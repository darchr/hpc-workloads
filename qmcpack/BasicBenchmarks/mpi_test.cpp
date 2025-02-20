#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

/*
 Purpose of this code is to ensure that MPI works on Gem5
 since qmcpack runs it unless deactivated with the cmake parameters.
 Requires mpi compilers.
 mpicxx mpi_hello_world.cpp -o mpi_hello
 mpirun -np 4 ./mpi_hello

 Since we are not running in actual multi-server environement,
 we don't require much testing of this feature. But mpi source code
 is coupled with all other source and could affect the final build 
 of qmcpack.
*/

int main(int argc, char *argv[])
{
    int rank;
    int size;

    int ierr = MPI_Init(&argc, &argv);
    if (ierr != MPI_SUCCESS) {
        fprintf(stderr, "ERROR: Failed to initialize MPI.\n");
        return EXIT_FAILURE;
    }

    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    printf("Hello from process %d of %d!\n", rank, size);
    MPI_Finalize();

    return EXIT_SUCCESS;
}
