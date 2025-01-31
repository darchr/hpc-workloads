# Use the official Ubuntu image from Docker Hub
FROM nvcr.io/nvidia/nvhpc:24.11-devel-cuda_multi-ubuntu22.04

# Set environment variables (optional)
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary packages
RUN apt-get update && \
    apt-get install -y \
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
    gcc \
    g++ \
    openmpi-bin \
    libopenmpi-dev \
    libfftw3-dev\
    libfftw3-bin\
    libxc-dev \
    doxygen \
    graphviz \
    pip && apt-get clean

RUN pip install numpy pandas h5py
RUN pip install --prefer-binary pyscf
# Set MPI paths (optional)
ENV PATH="/usr/lib64/openmpi/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:${LD_LIBRARY_PATH}"
# Set the working directory
WORKDIR /app/qmcpack
# Clone the QMCPACK repository
RUN git clone https://github.com/QMCPACK/qmcpack.git .
# Set the working directory inside the container
WORKDIR /app
# Expose ports (optional based on requirements)
EXPOSE 8000 80 3000 7000
# Command to keep the container running
CMD ["tail", "-f", "/dev/null"]

