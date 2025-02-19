# Building LSMS

This is a disk image used to build and run LSMS on gem5. I have used the /gem5-resources/src/ubuntu-generic-diskimages disk image as the base and have extended from there. I have made the following changes to install LSMS:

## /ubuntu-cpu-lsms/files/x86/gem5_init.sh

Removed the `gem5-bridge exit` command (Line 22) since this will exit the simulation.

## /ubuntu-cpu-lsms/files/x86/after_boot.sh

Removed the `gem5-bridge exit` command (Line 17) since this will exit the simulation.

## /ubuntu-cpu-lsms/http/x86/user-data

Changed the partition size to -1 at Line 61. This basically lets the partition to use all the available space remaining.

```
- device: disk-vda
        size: -1
        wipe: superblock
        number: 2
        preserve: false
        grub_device: false
        offset: 2097152
        type: partition
        id: partition-1
```

## /ubuntu-cpu-lsms/packer-scripts/x86-ubuntu.pkr.hcl

Edited the QEMU initialize settings at Line 49.

1. Increased cpus to 24.
2. Increased disk_size to 50000. Increase this more if you run out of space.
3. Increased memory to 131072 (128 GB). The LSMS make command uses upwards to 80 GB to install cleanly.

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
  disk_size        = "50000"
  format           = "raw"
  headless         = "true"
  http_directory   = "http/x86"
  iso_checksum     = local.iso_data[var.ubuntu_version].iso_checksum
  iso_urls         = [local.iso_data[var.ubuntu_version].iso_url]
  memory           = "131072"
  output_directory = local.iso_data[var.ubuntu_version].output_dir
  qemu_binary      = "/usr/bin/qemu-system-x86_64"
  qemuargs         = [["-cpu", "host"], ["-display", "none"]]
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  vm_name          = "${var.image_name}"
  ssh_handshake_attempts = "1000"
}
```

## /ubuntu-cpu-lsms/scripts/post-installation.sh

This is the actual script which installs all the dependencies. All I did was basically copy the dockerfile commands to build the image. The LSMS build script begins at Line 102. I have commented out the script which disables network at Line 124 because LSMS needs the internet to run.

## Building

You can run `./build-x86.sh 22.04` to build this disk image to run on ubuntu 22.04.

## File directory

```
Home
└───lsms
│   └───Test
│       │   Au
│       │   ...
|
└───build_lsms
    └───bin
        │   lsms
```

## Running

You can run the `lsms_cpu.py` file on gem5 to run a full system simulation which runs the Au LSMS simulation as a test. You can edit the command at Line 38 to run other lsms workloads.
