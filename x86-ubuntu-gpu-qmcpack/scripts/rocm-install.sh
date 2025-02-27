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
    libboost-dev \
    libreadline-dev \
    libhdf5-dev \
    libboost-all-dev \
    libatlas-base-dev \
    openmpi-bin \
    libopenmpi-dev \
    libfftw3-bin \
    libxc-dev \
    doxygen \
    graphviz
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
export GPU_TARGET="gfx90a,gfx942,gfx906"

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
sudo apt install -y \
    amdgpu-dkms \
    rocm \
    rocm-hip-sdk \
    hipblas \
    hipcub \
    hipsparse \
    hipfft \
    rocsolver \
    rocblas \
    rocrand \
    rocprim \
    rocthrust \
    libomp-dev
apt-get clean

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
export ROCM_PATH=/opt/rocm
# Add rocm/cmake to environment
export PATH=$ROCM_PATH/bin:/opt/cmake/bin:$PATH \
    LD_LIBRARY_PATH=$ROCM_PATH/lib:$ROCM_PATH

pip install numpy pandas h5py
pip install --prefer-binary pyscf


# QMCpack installation
echo "Installing QMCpack"
cd /home
git clone https://github.com/QMCPACK/qmcpack.git
mkdir build_qmcpack && cd build_qmcpack

cmake /home/qmcpack/ \
        -DCMAKE_C_COMPILER=hipcc \
        -DCMAKE_CXX_COMPILER=hipcc \
        -DQMC_GPU="hip" \
        -DQMC_GPU_ARCHS="gfx90a" \
        -DCMAKE_BUILD_TYPE=Release
make
echo "Post Installation Done"


# Setup gem5 auto login.
mv /home/gem5/serial-getty@.service /lib/systemd/system/

echo -e "\n/home/gem5/run_gem5_app.sh\n" >> /root/.bashrc