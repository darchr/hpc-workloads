#include <stdio.h>
#include <stdlib.h> // For EXIT_FAILURE
#include "hip/hip_runtime.h"

/*
Purpose of this program is to view the amount of memory
that the gpu has both total and free.
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

int main(int argc, char *argv[]) {
    
    hipDeviceProp_t props;
    
    CHECK(hipGetDeviceProperties(&props, 0 /*deviceID*/));
    printf ("The device %s\n", props.name);
    
    size_t free_mem, total_mem;
    
    // hipMemGetInfo retrieves the free and total amount of physical memory 
    // available for use by the device.
    CHECK(hipMemGetInfo(&free_mem, &total_mem));
    
    const float gigbytes = 1024.0f * 1024.0f * 1024.0f;

    printf("GPU Total Memory: %.2f GB\n", (float)total_mem / gigbytes);
    printf("GPU Free Memory:  %.2f GB\n", (float)free_mem / gigbytes);

    return 0;
}
