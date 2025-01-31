# QMCPACK on UC Davis Servers

## Installation
QMCPack has the capability to run with CUDA, HIP, OMP and MPI. 
Each of these frameworks comes with several tools required to compile the C++ code inside QMCPack.
The hard part is finding the right combination of tools that will build the executable properly.
This requires lots of trial and error and even then, the executable might be unstable leading to `Seg Faults`
and other errors. 

To help mitigate these kinds of errors, we have used Docker images that contain all the necessary components to 
build the executable for each platform. The Docker images are different and one Docker image cannot build the 
executable meant for another platform.

CUDA - https://developer.nvidia.com/cuda-toolkit - Acceleration via Nvidia GPU (different from AMD because of GPU architecture)
MPI  - https://www.open-mpi.org/faq/?category=general#what-is-mpi - Acceleration via parallelization with multicore, multicpu, and multiserver (clusters) operations
OMP  - https://www.openmp.org/resources/refguides/ - Acceleration via shared-memory parallelism with multicore systems with threading
HIP  - https://rocm.docs.amd.com/projects/HIP/en/docs-develop/what_is_hip.html - Acceleration via AMD GPU (different from Nvidia because of GPU architecture)

### Docker images
There are two directories, AMD and Nvidia. Each has its own docker files.
1. `$ cd` into the directory
    - Enter the GPU that you want to build for
2. `$ docker compose up -d` 
    - Build the container from scratch if you have not already. `-d` runs it in detached mode
3. `$ docker exec -it <container-name> /bin/bash`
    - Enter the docker image
4. `$ cd /app/qmcpack/build` 
    - Go to the build directory where all the CMake operations will take place
5. `$ cmake -key=value ..
    - You have to specify the options that you want CMake to prepare for the build
    - Found here: https://qmcpack.readthedocs.io/en/develop/installation.html
6. `$ make -j all`
    - Start the compilation of the executable. Will take a couple minutes
7. `$ ./bin/qmcpack <test-file>.xml`
    - Run a test program on the executable


