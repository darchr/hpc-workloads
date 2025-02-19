# Building LSMS with ROCm GPU Support

This guide provides instructions for building the LSMS with ROCm GPU support on AMD GPUs.

## Build Process Overview

The build process consists of two main steps:

### 1. Building the Base ROCm Docker Image

First, build the base ROCm GPU image that provides the fundamental GPU and MPI support.

Run the following command to build the base ROCm Docker image:

```bash
docker build -f Dockerfile.rocm-base -t rocm_gpu:6.3 .
```

### 2. Building the LSMS Docker Image

- Before building the LSMS Docker image, you need to create cmake file same as `hpcfund-rocm-hip.cmake` (Add a target architecture in cmake file, e.g: gfx90a, gfx942, gfx906)

- Run build command

```bash
docker build -f Dockerfile.gpu-amd -t lsms-amd-gpu .
```

- Run container in integrated mode (open container shell)

```bash
docker run --rm -it --device=/dev/kfd --device=/dev/dri/renderD128 --group-add video lsms-amd-gpu
```

- Find simulation with i_lsms file. Run simulation with command.

```bash
/opt/lsms/build/lsms i_lsms
```
