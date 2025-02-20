/*
Purpose of this code is to verify a couple things:
1. Create arrays in CPU memory and send them to GPU memory
    - Both pinned and unpinned
2. Verify that operations done on the data within the 
    arrays is successfull
*/

#include <stdio.h>
#include <stdlib.h> 
#include "hip/hip_runtime.h"

// Macro for error checking. Exits if a HIP API call fails.
// Took this from the sample code provided by AMD engineer
#define CHECK(cmd) \
{ \
    hipError_t error = cmd; \
    if (error != hipSuccess) { \
        fprintf(stderr, "error: '%s'(%d) at %s:%d\n", hipGetErrorString(error), error, __FILE__, __LINE__); \
        exit(EXIT_FAILURE); \
    } \
}

// This is the "kernel" which is a specific function
// that will be executed by the threads in the gpu
template <typename T>
__global__ void
vector_square(T *C_d, const T *A_d, size_t N)
{
    // These variables are define by HIP runtime
    size_t offset = (hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x);
    size_t stride = hipBlockDim_x * hipGridDim_x;

    for (size_t i = offset; i < N; i += stride) {
        C_d[i] = A_d[i] * A_d[i];
    }
}


int main(int argc, char *argv[])
{
    
    // d for device. GPU memory
    float *A_d, *C_d;
    // h for Host, CPU memory
    float *A_h, *C_h; 
    
    const size_t N = 1000000; // Total number of elements (1 million)
    const size_t Nbytes = N * sizeof(float);

    hipDeviceProp_t props;
    CHECK(hipGetDeviceProperties(&props, 0 /*deviceID*/));
    printf ("Device name is %s\n", props.name);
    #ifdef __HIP_PLATFORM_HCC__
      printf ("The specific GPU architecture is: %d\n", props.gcnArch); // This should print out the "VEGA..."
    #endif

    // allocate the arrays in the host cpu
    // A will hold the initial values
    // C will hold the result after the calculation
    A_h = (float*)malloc(Nbytes);
    C_h = (float*)malloc(Nbytes);
    if (!A_h || !C_h) {
        fprintf(stderr, "error: Host memory allocation failed!\n");
        exit(EXIT_FAILURE);
    }
    
    // hipMalloc allocates array directly in the gpu device
    CHECK(hipMalloc(&A_h, Nbytes));
    CHECK(hipMalloc(&C_h, Nbytes));

    // initialize the memory
    for (size_t i = 0; i < N; i++) {
        A_h[i] = 1.618f + (float)i; 
    }

    // copy the initial values from CPU A array to GPU A array
    hipMemcpy(A_d, A_h, Nbytes, hipMemcpyHostToDevice)

    
    // Define launch parameters:
    // THIS IS BASED ON THE AMD GPU BEING TESTED!
    const unsigned blocks = 512;
    const unsigned threadsPerBlock = 256;

    printf ("info: launch 'vector_square' kernel\n");
    
    hipLaunchKernelGGL(vector_square, dim3(blocks), dim3(threadsPerBlock), 0, 0, C_d, A_d, N);
    
    // Wait for the device to finish execution before checking the results on the host
    CHECK(hipDeviceSynchronize());

    // Copy the result from GPU mem to CPU mem
    hipMemcpy(C_h, C_d, Nbytes, hipMemcpyDeviceToHost)

    printf ("info: check result\n");
    for (size_t i = 0; i < N; i++) {
        if (C_h[i] != A_h[i] * A_h[i]) {
            fprintf(stderr, "Verification failed at index %zu: Expected %f, got %f\n", i, A_h[i] * A_h[i], C_h[i]);
            CHECK(hipErrorUnknown); // This is a failure macro within HIP api
        }
    }
    
    // --- 6. Cleanup ---
    CHECK(hipFree(A_d));
    CHECK(hipFree(C_d));
    free(A_h);
    free(C_h);
    
    printf ("PASSED!\n");
    return 0;
}
