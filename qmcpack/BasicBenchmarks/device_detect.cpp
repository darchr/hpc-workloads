#include <stdio.h>
#include <iostream>

/* 
The purpose of this program is to ensure that the compiler can be detected by 
macros. Within QMCPack, the specific code that will be run is determined by the 
presence of these macros.
*/

int main() {
    #if defined(__CUDACC__) || defined(__CUDA__) || defined(__NVCC__)
        printf("Detected: NVIDIA CUDA Compiler (NVCC) or CUDA environment.\n");
    #elif defined(__HIPCC__)
        printf("Detected: AMD HIP Compiler (HIPCC) or HIP environment.\n");
    #else
        printf("Detected: Unknown/Standard C++ Compiler.\n");
    #endif    
    return 0;
}
