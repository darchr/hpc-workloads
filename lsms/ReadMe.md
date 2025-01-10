# LSMS Project Documentation

## Description
This project involves docs for running the LSMS code. A Docker image has been created to run the project on x86 machines, specifically tested on Amarillo.

## Steps to Run the Project for CPU only (Use DockerFile: Dockerfile-cpu)

### 1. Build the Docker Image
To build the Docker image, execute the following command in the directory containing the Dockerfile:
```bash
docker build -t lsms-docker .
```

### 2. Run the Docker Container
Start the container in detached mode with automatic restart enabled:
```bash
docker run -d --restart unless-stopped lsms-docker
```

### 3. Open Bash in the Docker Container
Access the container’s bash shell:
```bash
docker exec -it <container_id> bash
```
Replace `<container_id>` with the actual container ID or name.

### 4. Navigate to Configuration Files
Once inside the container, navigate to the directory containing configuration files:
```bash
cd /usr/src/app/lsms/Test/
```

### 5. Select the Workload Directory
This directory contains multiple workloads. Navigate to the specific directory with the `i_lsms` file for your desired element.

### 6. Run the LSMS Project
Run the LSMS simulation with the following command:
```bash
mpirun --allow-run-as-root -np 1 /usr/src/app/build_lsms/bin/lsms i_lsms
```

Ensure the `i_lsms` file is present in the current directory before running the command.

## Steps to Run the Project for GPU (Use DockerFile: Dockerfile-gpu)

### 1. Build the Docker Image
To build the Docker image, execute the following command in the directory containing the Dockerfile:
```bash
docker build -t lsms-gpu .
```

### 2. Run the Docker Container
```bash
docker run --gpus all -dit --name lsms-container lsms-gpu
```

### 3. Open Bash in the Docker Container
Access the container’s bash shell:
```bash
docker exec -it <container_id> bash
```
Replace `<container_id>` with the actual container ID or name.

### 4. Navigate to Configuration Files
Once inside the container, navigate to the directory containing configuration files:
```bash
cd /usr/src/app/lsms/Test/
```

### 5. Select the Workload Directory
This directory contains multiple workloads. Navigate to the specific directory with the `i_lsms` file for your desired element.

### 6. Run the LSMS Project
Run the LSMS simulation with the following command:
```bash
/usr/src/app/build_lsms/bin/lsms i_lsms
```

Ensure the `i_lsms` file is present in the current directory before running the command.

# Code Description

## Introduction
The LSMS  code is a computational tool designed for first-principles calculations of the electronic structure of materials. Using **density functional theory (DFT)** and **multiple scattering theory**, LSMS enables the simulation of material properties such as magnetism, electronic structure, and chemical bonding at the atomic scale.

### Key Features
- **Muffin-Tin Approximation (MT)**:
  - Divides space into spherical regions around atoms (muffin-tin regions) and an interstitial region.
  - Simplifies calculations of electron densities and potentials.
- **Voronoi Polyhedra Construction**:
  - Defines atomic neighborhoods using Voronoi cells.
  - Calculates interactions between atoms based on spatial distribution.
- **Self-Consistent Field (SCF) Method**:
  - Iteratively solves for the electron density until equilibrium is reached.
- **Spin Polarization**:
  - Handles spin-polarized systems for studying magnetic properties.

## Purpose of the Code
The LSMS code is used to:
1. Calculate the electronic structure of materials.
2. Determine magnetic properties, such as the magnetic moment of atoms.
3. Compute the total energy of the system, which is critical for stability analysis.
4. Analyze the interaction between atoms in the system.

## Output Details
The output from LSMS includes:
- **Total Energy**: The energy of the system (reported in Rydbergs).
- **Fermi Energy**: The energy level at which electron states are filled.
- **Band Energy**: The contribution of band electrons to the system's total energy.
- **Magnetic Moments**: Spin and magnetic moments for each atom.
- **Core State Energies**: Energy levels of core and semicore states.
- **Charge Distribution**: Total charge and charge distribution across the system.

> **Tip:** You can see `lsms/docs/LSMS-Tutorial v2.pdf` to understand more about project and it's output details.
