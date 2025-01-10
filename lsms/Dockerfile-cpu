# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    gfortran \
    cmake \
    git \
    wget \
    curl \
    libhdf5-dev \
    libblas-dev \
    liblapack-dev \
    libopenmpi-dev \
    openmpi-bin \
    libtool \
    libreadline-dev \
    python3 \
    python3-pip \
    python3-dev \
    && apt-get clean

# Verify gfortran version
RUN gfortran --version

# Set working directory
WORKDIR /usr/src/app

# Clone the LSMS repository
RUN git clone https://github.com/mstsuite/lsms.git

# Create a build directory
RUN mkdir -p build_lsms

# Set build arguments for CMake
WORKDIR /usr/src/app/build_lsms

# Configure LSMS with CMake
RUN cmake ../lsms \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=mpic++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_Fortran_COMPILER=gfortran \
    -DCMAKE_CXX_FLAGS="-O3 -mtune=native" \
    -DCMAKE_Fortran_FLAGS="-O3 -mtune=native -fbacktrace -cpp -fallow-argument-mismatch" \
    -DBLA_VENDOR=Generic

# Build LSMS
RUN cmake --build . --parallel

# Set LSMS binary path
ENV PATH="/usr/src/app/build_lsms/bin:$PATH"

# Default command to show LSMS version
CMD ["bash"]
