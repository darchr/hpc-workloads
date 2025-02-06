# Toolchain configuration for building LSMS with HIP on AMD GPUs
# Adapted from LSMS official toolchain for Frontier
# see https://github.com/mstsuite/lsms/blob/master/toolchain/frontier-rocm-hip.cmake
set(SEARCH_LAPACK OFF)
set(SEARCH_BLAS OFF)
set(AMDGPU_TARGETS "gfx90a;gfx942;gfx906")
set(GPU_TARGETS "gfx90a;gfx942;gfx906")
set(USE_ACCELERATOR_HIP ON)
set(MST_LINEAR_SOLVER_DEFAULT 0x0020)
set(MST_BUILD_KKR_MATRIX_DEFAULT 0x3000)
