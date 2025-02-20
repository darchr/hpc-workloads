#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

/*
Purpose of this program is to ensure that omp 
can be executed on the cpu side of gem5. 
The thread count is set as an env variable on the system. 
QMCPack executes several threads on the cpu that each will 
run the HIP threads on the GPU side.

Need to install the openmp library to be able to link during 
compilation.

*/

int main(int argc, char *argv[])
{
    printf("OpenMP 'Hello World' Test\n");
    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        int num_threads = omp_get_num_threads();

        printf("Hello from thread %d of %d\n", thread_id, num_threads);
    }
    
    printf("Done\n");

    return EXIT_SUCCESS;
}
