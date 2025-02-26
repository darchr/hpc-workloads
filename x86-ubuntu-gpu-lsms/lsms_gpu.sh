export HDF5_PATH=/usr/local/hdf5
export LD_LIBRARY_PATH=$HDF5_PATH/lib:$LD_LIBRARY_PATH

cd /home/lsms/Test/Fe16
/opt/ompi/bin/mpirun -allow-run-as-root /home/build_lsms/bin/lsms i_lsms