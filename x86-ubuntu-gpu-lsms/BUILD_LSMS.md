# Building LSMS

This is a disk image used to build and run LSMS on gem5. I have used the /gem5-resources/src/x86-ubuntu-gpu-ml disk image as the base and have extended from there. I have made the following changes to install LSMS:

## /x86-ubuntu-gpu-lsms/files/

Added the `hpcfund-rocm-hip.cmake` file to upload into the VM.

## /x86-ubuntu-gpu-lsms/x86-ubuntu-gpu-ml.pkr.hcl

Edited the QEMU initialize settings at Line 49.

1. Increased cpus to 24.
2. Increased memory to 131072 (128 GB). The LSMS make command uses upwards to 80 GB to install cleanly.
3. Added script to upload the `hpcfund-rocm-hip.cmake` file.

```
source "qemu" "initialize" {
  accelerator      = "kvm"
  boot_command     = ["e<wait>",
                      "<down><down><down>",
                      "<end><bs><bs><bs><bs><wait>",
                      "autoinstall  ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
                      "<f10><wait>"
                    ]
  cpus             = "24"
  disk_size        = "56000"
  format           = "raw"
  headless         = "true"
  http_directory   = "http"
  iso_checksum     = "sha256:5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  iso_urls         = ["https://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.2-live-server-amd64.iso"]
  memory           = "131072"
  output_directory = "disk-image"
  qemu_binary      = "/usr/bin/qemu-system-x86_64"
  qemuargs         = [["-cpu", "host"], ["-display", "none"]]
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  vm_name          = "${var.image_name}"
  ssh_handshake_attempts = "1000"
}

provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/hpcfund-rocm-hip.cmake"
  }
```

## /x86-ubuntu-gpu-lsms/scripts/rocm-install.sh

This is the actual script which installs all the dependencies. I have added comments to explain what each command does.

## Building

You can run `./build.sh` to build this disk image to run on ubuntu 22.04.

### IMPORTANT

You must first edit the `/gem5/src/dev/io_device.hh` and comment out the assertion at line 79 and then rebuild the /VEGA_X86/gem5.opt binary. If you do not do this, then the simulation will crash when you execute mpirun.

## Running

You can have a look at the `lsms_gpu.sh` file to see the script to run an LSMS test. However for debugging I recommend running a `tail -f /dev/null` command to make the simulation run indefinitely and then use m5term to enter the simulation to play around with the files and commands.

## TO-DO

LSMS currently runs on the GPU and can execute test workloads. However further testing must be done on the stability and speed, since the processing speed is very slow. Some test workloads such as Au/ and Cu/ can cause CPU lockups as well.
