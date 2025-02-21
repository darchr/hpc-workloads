# Building LSMS with ROCm GPU Support

This guide provides instructions for building the LSMS with ROCm GPU support on AMD GPUs.

## Build Process Overview

The build process consists of two main steps:

### 1. Building the Base ROCm Docker Image

First, build the base ROCm GPU image that provides the fundamental GPU and MPI support.

Run the following command to build the base ROCm Docker image:

```bash
docker build -t rocm_gpu:6.3 -f /path/to/Dockerfile-rocm-base .
```

### 2. Building the LSMS Docker Image

- Before building the LSMS Docker image, you need to create cmake file same as ```hpcfund-rocm-hip.cmake``` (Add a target architecture in cmake file, e.g: gfx90a, gfx942, gfx906)

- Run build command ``` docker build -t lsms-amd-gpu . ```

- Run container with command ``` docker run --rm -it --device=/dev/kfd --device=/dev/dri --group-add video --gpus all lsms-amd-gpu ```

- You will be in exec terminal inside container after this. In this container go to path for element i_lsms file.

- Run simulation with command ``` /opt/lsms/build/lsms i_lsms ```

