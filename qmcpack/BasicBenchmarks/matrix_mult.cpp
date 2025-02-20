#include <stdio.h>
#include <stdlib.h> // For EXIT_FAILURE
#include <math.h>   // For fabsf (floating point comparison)
#include "hip/hip_runtime.h"

/*
This code does raw matrix multiplication using the standard row and column
method. 
Here we are checking for:
1. Access to the hipHostMalloc() function
  - This removes the need to manually allocate and free the memory in the host
  - Also pins the memmory in the page and does not allow it to be paged to the disk
    rather, it keeps in the ram pages. 
  - HIP will automatically handle the copy of the CPU mem to GPU and back. 
*/

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


//  Matrix Multiplication Kernel (C = A * B) 
/*
 * Kernel: Performs C = A * B using 2D thread indexing.
 * Each thread calculates a single element C[row][col]. (Doing parallel processing)
 * M, N, K define the matrix dimensions: A(M x K), B(K x N), C(M x N).
 */
template <typename T>
__global__ void
matrix_multiply(const T *A_d, const T *B_d, T *C_d, size_t M, size_t N, size_t K) {
    // Calculate the row index for C (using Y-axis variables)
    size_t row = hipBlockIdx_y * hipBlockDim_y + hipThreadIdx_y;
    // Calculate the column index for C (using X-axis variables)
    size_t col = hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x;

    // Check bounds: Ensure the thread is within the matrix dimensions
    if (row < M && col < N) {
        T Cvalue = 0;
        // Dot product loop: iterate over the shared dimension K
        for (size_t k = 0; k < K; ++k) {
            // C[row][col] += A[row][k] * B[k][col]
            Cvalue += A_d[row * K + k] * B_d[k * N + col];
        }
        C_d[row * N + col] = Cvalue;
    }
}

int main(int argc, char *argv[])
{
    const size_t MatrixSize = 32;
    const size_t M = MatrixSize; 
    const size_t K = MatrixSize; 
    const size_t N = MatrixSize; 
    
    
    const size_t A_Nbytes = M * K * sizeof(float);
    const size_t B_Nbytes = K * N * sizeof(float);
    const size_t C_Nbytes = M * N * sizeof(float);

    // CPU pointers (will be allocated as Pinned Memory)
    float *A_h, *B_h, *C_h;
    // CPU Reference pointer (still regular heap memory for CPU math)
    float *C_ref; 
    
    hipDeviceProp_t props;
    CHECK(hipGetDeviceProperties(&props, 0));
    printf ("Running on device %s\n", props.name);
    printf ("Matrix Multiplication (C = A * B) - Size %zux%zu x %zux%zu\n", M, K, K, N);
    
    // allocate the memory on both GPU and CPU
    printf("info: allocating Pinned Memory using hipHostMalloc...\n");
    CHECK(hipHostMalloc(&A_h, A_Nbytes));
    CHECK(hipHostMalloc(&B_h, B_Nbytes));
    CHECK(hipHostMalloc(&C_h, C_Nbytes)); // GPU Result memory
    
    // Allocate CPU memory for the validation at the end.
    // This will hold the result done by CPU to compare
    C_ref = (float*)malloc(C_Nbytes);
    if (!A_h || !B_h || !C_h || !C_ref) {
        fprintf(stderr, "error: Memory allocation failed!\n");
        exit(EXIT_FAILURE);
    }

    // initialize the memory
    for (size_t i = 0; i < M * K; i++) { 
      A_h[i] = (float)(i % 5) + 1.0f; 
    } 
    for (size_t i = 0; i < K * N; i++) {
      B_h[i] = (float)(i % 7) + 1.0f; 
    } 
    
    // Set up the thread counts 
    const unsigned threadsPerBlock = 16;
    
    // Calculate grid dimensions needed to cover M rows and N columns
    dim3 dimBlock(threadsPerBlock, threadsPerBlock);
    dim3 dimGrid((N + dimBlock.x - 1) / dimBlock.x, (M + dimBlock.y - 1) / dimBlock.y);
    
    printf ("Doing the matrix multiplication\n");
    
    // The data from the arrays is automatically loaded by the HIP runtime
    hipLaunchKernelGGL(matrix_multiply, dimGrid, dimBlock, 0, 0, 
                       A_h, B_h, C_h, M, N, K);
    
    // wait till execution is complete
    CHECK(hipDeviceSynchronize());
    
    for (size_t row = 0; row < M; ++row) {
        for (size_t col = 0; col < N; ++col) {
            float sum = 0.0f;
            for (size_t k = 0; k < K; ++k) {
                // Accessing elements in row-major order
                sum += A_h[row * K + k] * B_h[k * N + col];
            }
            C_ref[row * N + col] = sum;
        }
    }
    
    // Compare GPU result (C_h) with CPU result (C_ref)
    size_t failures = 0;
    for (size_t i = 0; i < M * N; i++) {
        // Use a small tolerance for floating point comparison
        if (fabsf(C_h[i] - C_ref[i]) > 1e-5) {
            failures++;
            if (failures < 10) { // Only print the first few failures
                 fprintf(stderr, "Verification failed at index %zu: GPU=%f, CPU=%f\n", 
                         i, C_h[i], C_ref[i]);
            }
        }
    }
    
    if (failures > 0) {
        fprintf(stderr, "FAILURE! Total mismatches: %zu\n", failures);
        CHECK(hipErrorUnknown); 
    }
    
    // free the memory from both the cpu and gpu 
    CHECK(hipHostFree(A_h));
    CHECK(hipHostFree(B_h));
    CHECK(hipHostFree(C_h));
    
    free(C_ref);
    
    printf ("PASSED!\n");
    return 0;
}
