#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "hip/hip_runtime.h"

/*
Purpose of this program to ensure that a program compiled with hip 
can still be run with OMP macros when linked with OMP.
QMCPack has this configuration. 
*/

// Macro for error checking. Exits if a HIP API call fails.
// Took this from the sample code provided by AMD engineer
#define CHECK(cmd) \
{ \
    hipError_t error = cmd; \
    if (error != hipSuccess) { \
        fprintf(stderr, "HIP Error: '%s'(%d) at %s:%d\n", hipGetErrorString(error), error, __FILE__, __LINE__); \
        exit(EXIT_FAILURE); \
    } \
}

int main(int argc, char *argv[])
{
    const size_t N = 1024 * 1024; 
    const size_t Nbytes = N * sizeof(float);

    float *A_h, *B_h, *C_h;

    printf("N = %zu elements\n", N);
    
    // Allocate mem on both GPU and CPU. 
    CHECK(hipHostMalloc((void**)&A_h, Nbytes));
    CHECK(hipHostMalloc((void**)&B_h, Nbytes));
    CHECK(hipHostMalloc((void**)&C_h, Nbytes));

    // Initialize Host Input Arrays
    for (size_t i = 0; i < N; i++) {
        A_h[i] = (float)i;
        B_h[i] = 1.0f;
    }

    // Begin the OMP code
    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        int num_threads = omp_get_num_threads();
        
        if (thread_id == 0) {
            printf("\n[OMP Master Thread %d of %d] -> Pinned Memory is ready for GPU offload or access.\n", thread_id, num_threads);

            
        } else {
            printf("[OMP Worker Thread %d of %d] -> Performing concurrent CPU work.\n", thread_id, num_threads);
            for (int i = 0; i < 100000; ++i);  // Random for loop that "simulates" work being done
        }
    }

    // Free the memory on both cpu and gpu
    CHECK(hipHostFree(A_h));
    CHECK(hipHostFree(B_h));
    CHECK(hipHostFree(C_h));
    
    printf("Passed");

    return EXIT_SUCCESS;
}
