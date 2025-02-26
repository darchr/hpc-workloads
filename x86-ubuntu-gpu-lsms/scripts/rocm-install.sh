#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

echo 'Post Installation Started'

# Installing the packages in this script instead of the user-data
# file dueing ubuntu autoinstall. The reason is that sometimes
# the package install failes. This method is more reliable.
echo 'installing packages'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    ssh \
    make \
    vim \
    nano \
    libtinfo-dev\
    initramfs-tools \
    libelf-dev \
    numactl \
    curl \
    wget \
    tmux \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libnuma-dev \
    gfortran \
    flex \
    hwloc \
    libstdc++-12-dev \
    libxml2-dev \
    python3-dev \
    python3-pip \
    scons\
    gpg \
    libblas-dev \
    liblapack-dev \
    libfftw3-dev \
    libxml2-dev \
    libboost-dev \
    libreadline-dev \
    pkg-config \
    libxc-dev \
    lua5.4 \
    liblua5.4-dev
apt-get clean

# Remove the motd
rm /etc/update-motd.d/*

# Build the m5 util
git clone https://github.com/gem5/gem5.git --depth=1 --filter=blob:none --no-checkout --sparse --single-branch --branch=stable
pushd gem5
# Checkout just the files we need
git sparse-checkout add util/m5
git sparse-checkout add include
git checkout
# Build the library and binary
pushd util/m5
scons build/x86/out/m5
cp build/x86/out/m5 /sbin/m5
popd
popd
rm -rf gem5


# Make sure the headers are installed to extract the kernel that DKMS
# packages will be built against.
sudo apt -y install "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"

echo "Extracting linux kernel"
sudo bash -c "/usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux /boot/vmlinuz-$(uname -r) > /home/gem5/vmlinux-gpu-ml"

# Make directory for GPU BIOS. These are placed in /root for compatibility with
# the legacy GPUFS configs.
sudo mkdir -p /root/roms
sudo chmod 777 /root
sudo chmod 777 /root/roms


# ROCm Installation
export UCX_BRANCH="v1.17.0" \
UCC_BRANCH="v1.3.0" \
OMPI_BRANCH="v5.0.5" \
GPU_TARGET="gfx90a,gfx942,gfx906"

# Make the directory if it doesn't exist yet.
# This location is recommended by the distribution maintainers.
sudo mkdir --parents --mode=0755 /etc/apt/keyrings

# Download the key, convert the signing-key to a full
# keyring required by apt and store in the keyring directory
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
        gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# Register kernel-mode driver
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/amdgpu/6.1/ubuntu jammy main" \
        | sudo tee /etc/apt/sources.list.d/amdgpu.list

# Register ROCm packages
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.1 jammy main" \
        | sudo tee --append /etc/apt/sources.list.d/rocm.list
echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
        | sudo tee /etc/apt/preferences.d/rocm-pin-600
sudo apt update
sudo apt install -y amdgpu-dkms
sudo apt install -y rocm
sudo apt install -y rocm-hip-sdk


# Add GPU targets to the ROCm target list
bash -c """IFS=',' read -r -a ARCH <<<$GPU_TARGET \
    &&  for gpu_arch in \${ARCH[@]}; do \
    echo \$gpu_arch  >> /opt/rocm/bin/target.lst; \
    done""" \
    && chmod a+r /opt/rocm/bin/target.lst 

# Give all users permission to access GPU devices
touch /etc/udev/rules.d/70-amdgpu.rules
cat << EOF >> /etc/udev/rules.d/70-amdgpu.rules
KERNEL=="kfd", MODE="0666"
SUBSYSTEM=="drm", KERNEL=="renderD*", MODE="0666"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger


# Cmake > 3.22
mkdir -p /opt/cmake
wget --no-check-certificate --quiet -O - https://cmake.org/files/v3.30/cmake-3.30.5-linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /opt/cmake

# Install paths
export ROCM_PATH=/opt/rocm \
    UCX_PATH=/opt/ucx \
    UCC_PATH=/opt/ucc \
    OMPI_PATH=/opt/ompi


# Add rocm/cmake to environment
export PATH=$ROCM_PATH/bin:/opt/cmake/bin:$PATH \
    LD_LIBRARY_PATH=$ROCM_PATH/lib:$ROCM_PATH/lib64:$ROCM_PATH/llvm/lib:$LD_LIBRARY_PATH \
    LIBRARY_PATH=$ROCM_PATH/lib:$ROCM_PATH/lib64:$LIBRARY_PATH \
    C_INCLUDE_PATH=$ROCM_PATH/include:$C_INCLUDE_PATH \
    CPLUS_INCLUDE_PATH=$ROCM_PATH/include:$CPLUS_INCLUDE_PATH \
    CMAKE_PREFIX_PATH=$ROCM_PATH/lib/cmake:$CMAKE_PREFIX_PATH


# UCX Installation
cd /tmp
git clone https://github.com/openucx/ucx.git -b $UCX_BRANCH
cd ucx 
./autogen.sh 
mkdir build 
cd build 
../contrib/configure-release --prefix=$UCX_PATH \
        --with-rocm=$ROCM_PATH \
        --without-knem \
        --without-xpmem  \
        --without-cuda \
        --enable-optimizations  \
        --disable-logging \
        --disable-debug \
        --disable-examples 
make -j $(nproc)  
make install


# UCC Installation
cd /tmp
git clone -b $UCC_BRANCH https://github.com/openucx/ucc
cd ucc
./autogen.sh
sed -i 's/memoryType/type/g' ./src/components/mc/rocm/mc_rocm.c
sed -i 's/--offload-arch=native//g' ./cuda_lt.sh
mkdir build
cd build
../configure --prefix=$UCC_PATH --with-rocm=$ROCM_PATH --with-ucx=$UCX_PATH --with-rccl=no 
make -j $(nproc)
make install


# OpenMPI Installation
cd /tmp
git clone --recursive https://github.com/open-mpi/ompi.git -b $OMPI_BRANCH
cd ompi
./autogen.pl
mkdir build
cd build
../configure --prefix=$OMPI_PATH --with-ucx=$UCX_PATH --with-ucc=$UCC_PATH \
        --enable-mca-no-build=btl-uct  \
        --without-verbs \
        --with-pmix=internal \
        --enable-mpi \
        --enable-mpi-fortran=yes \
        --disable-man-pages \
        --disable-debug
make -j $(nproc)
make install


# Adding OpenMPI, UCX, and UCC to Environment
export PATH=$OMPI_PATH/bin:$UCX_PATH/bin:$UCC_PATH/bin:$PATH \
    LD_LIBRARY_PATH=$OMPI_PATH/lib:$UCX_PATH/lib:$UCC_PATH/lib:$LD_LIBRARY_PATH \
    LIBRARY_PATH=$OMPI_PATH/lib:$UCX_PATH/lib:$UCC_PATH/lib:$LIBRARY_PATH \
    C_INCLUDE_PATH=$OMPI_PATH/include:$UCX_PATH/include:$UCC_PATH/include:$C_INCLUDE_PATH \
    CPLUS_INCLUDE_PATH=$OMPI_PATH/include:$UCX_PATH/include:$UCC_PATH/include:$CPLUS_INCLUDE_PATH \
    PKG_CONFIG_PATH=$OMPI_PATH/lib/pkgconfig:$UCX_PATH/lib/pkgconfig/:$PKG_CONFIG_PATH  \
    OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
    UCX_WARN_UNUSED_ENV_VARS=n

echo "Check if OpenMPI and UCX are installed with ROCm"
ucx_info -v
# Configured with: --disable-logging --disable-debug --disable-assertions --disable-params-check --prefix=/opt/ucx --with-rocm=/opt/rocm --without-knem --without-xpmem --without-cuda --enable-optimizations --disable-logging --disable-debug --disable-examples
ompi_info | grep "MPI extensions"
# MPI extensions: affinity, cuda, ftmpi, rocm
echo "Check if OpenMPI runs"
mpirun hostname


# HDF5 installaton
echo "Installing HDF5"
export HDF5_PATH=/usr/local/hdf5
cd /tmp
git clone --recursive https://github.com/HDFGroup/hdf5.git -b hdf5-1_14_1 
cd hdf5 
CC=$OMPI_PATH/bin/mpicc ./configure --prefix=$HDF5_PATH --enable-parallel 
make -j 24
make install 
echo "HDF5 installed"


export export PATH=$PATH:$HDF5_PATH \
    LD_LIBRARY_PATH=$HDF5_PATH/lib:$LD_LIBRARY_PATH \
    LIBRARY_PATH=$HDF5_PATH/lib:$LIBRARY_PATH \
    C_INCLUDE_PATH=$HDF5_PATH/include:$C_INCLUDE_PATH \
    CPLUS_INCLUDE_PATH=$HDF5_PATH/include:$CPLUS_INCLUDE_PATH \
    PKG_CONFIG_PATH=$HDF5_PATH/lib/pkgconfig:$PKG_CONFIG_PATH \
    HSA_XNACK=1 \
    OMPX_APU_MAPS=1 \
    OMP_NUM_THREADS=4 \
    AMDDeviceLibs_DIR=$ROCM_PATH/lib/cmake


# LSMS Setup
echo "LSMS Setup"
cd /home
git clone https://github.com/mstsuite/lsms.git
cp ./gem5/hpcfund-rocm-hip.cmake ./lsms/toolchain/hpcfund-rocm-hip.cmake

mkdir build_lsms
cd build_lsms

cmake ../lsms \
    -DCMAKE_PREFIX_PATH=/opt/rocm \
    -DCMAKE_TOOLCHAIN_FILE="../lsms/toolchain/hpcfund-rocm-hip.cmake" \
    -DCMAKE_CXX_COMPILER=$ROCM_PATH/bin/hipcc \
    -DCMAKE_C_COMPILER=$ROCM_PATH/bin/hipcc \
    -DBLAS_LIBRARIES=/usr/lib/x86_64-linux-gnu/libblas.so \
    -DLAPACK_LIBRARIES=/usr/lib/x86_64-linux-gnu/liblapack.so

cmake --build . --parallel
echo "LSMS built"
export PATH=/home/lsms/build/bin:$PATH
echo "Post Installation Done"


# Setup gem5 auto login.
mv /home/gem5/serial-getty@.service /lib/systemd/system/

echo -e "\n/home/gem5/run_gem5_app.sh\n" >> /root/.bashrc