# Use an AMD ROCm development image as the base
FROM rocm/dev-ubuntu-22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ROCM_PATH=/opt/rocm
ENV PATH=$ROCM_PATH/bin:$PATH
ENV LD_LIBRARY_PATH=$ROCM_PATH/lib:$LD_LIBRARY_PATH
ENV HIP_PLATFORM=amd

# Update package list and install required dependencies
RUN apt-get update && \
    apt-get install -y \
    wget \
    curl \
    vim \
    git \
    build-essential \
    cmake \
    libxml2-dev \
    libhdf5-dev \
    libboost-all-dev \
    libatlas-base-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    openmpi-bin \
    libopenmpi-dev \
    libfftw3-dev \
    libfftw3-bin \
    libxc-dev \
    doxygen \
    graphviz \
    python3-pip && \
    apt-get clean

# Install ROCm libraries for HIP support
RUN apt-get update && \
    apt-get install -y \
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
    libomp-dev \
    && apt-get clean

# Set up MPI for HIP-enabled execution
RUN echo "export PATH=/opt/rocm/bin:$PATH" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH" >> ~/.bashrc

RUN pip install numpy pandas h5py
RUN pip install --prefer-binary pyscf

# Set the working directory
WORKDIR /app/qmcpack

# Clone the QMCPACK repository
RUN git clone https://github.com/QMCPACK/qmcpack.git .

# Create a build directory
#WORKDIR /app/qmcpack/build
WORKDIR /app

# Run CMake with HIP support
#RUN cmake -DCMAKE_C_COMPILER=hipcc \
#          -DCMAKE_CXX_COMPILER=hipcc \
#          -DQMC_GPU="openmp;hip" \
#          -DQMC_GPU_ARCHS="gfx90a" \
#          -DCMAKE_BUILD_TYPE=Release ..

# Build QMCPACK
#RUN make -j $(nproc)

# Default command to open a shell
CMD ["tail", "-f", "/dev/null"]

