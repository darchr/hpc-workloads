# Update on LSMS Code

## Progress Till End of Fall Quarter

### **Single-Core Execution**
- Ran the LSMS code on the **Amarillo machine** using a `Dockerfile` designed for non-GPU systems.
- The code is functioning perfectly in a single-core environment.
- Tested with the material configuration file located at:
  ```
  lsms/Test/Summit-Acceptance/FePt/i-lsms
  ```
- According to the configuration file, the workload executes **50 iterations**.
  - Each iteration takes approximately **20 minutes** to complete.
  - The workload is designed for **2 atoms**.
- Command used:
  ```bash
  mpirun --allow-run-as-root -np 1 /usr/src/app/build_lsms/bin/lsms i_lsms
  ```

### **Multi-Core Execution**
- Attempted to run the code using **10 cores**.
  - Command executed successfully.
  - However, **no speedup** was observed; each iteration still takes ~20 minutes to complete.

### **Segmentation Fault Issue**
- After a few iterations in the multi-core environment, the following error was encountered:
  ```
  ----------------------------------------
  Primary job terminated normally, but 1 process returned
    a non-zero exit code. Per user-direction, the job has been aborted.
  -----------------------------------------
  -----------------------------------------
  mpirun noticed that process rank 9 with PID 0 on node 23b618774973 exited on signal 11 (Segmentation fault).
  ------------------------------------------
  ```
- This indicates a **segmentation fault**, possibly due to memory allocation or parallelization issues.

## Next Steps
1. Investigate the lack of speedup in multi-core execution.
   - Profile the code to identify potential bottlenecks.
   - Verify if the workload supports parallel scaling.
2. Debug the segmentation fault.
   - Check memory usage and thread synchronization.
   - Review the MPI setup and configuration.
3. Explore running the code on a **GPU-enabled machine** to evaluate performance improvements.

## Update from Last Issue
- Found out why speedup was not there: according to the code, you can only use less than or equal to the number of cores as `num_atoms`.
- **Segmentation fault** is no longer occurring when running based on the above constraint.
- Successfully ran the code in a **GPU setup** and observed significant speedup in the system.

#### Performance Comparisons:
- **1 interaction, 2 atoms, 1 CPU:** 19:30
- **1 interaction, 2 atoms, 2 CPUs:** 13:04
- **5 interactions, 2 atoms, with GPU:** 40.30 sec
- **28 interactions, 2 atoms, with GPU:** 214.55 sec
