# Copyright (c) 2024 Advanced Micro Devices, Inc.
# All rights reserved.
# SPDX-License-Identifier: BSD 3-Clause

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "image_name" {
  type    = string
  default = "x86-ubuntu-gpu-ml"
}

variable "ssh_password" {
  type    = string
  default = "12345"
}

variable "ssh_username" {
  type    = string
  default = "gem5"
}

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

build {
  sources = ["source.qemu.initialize"]

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/run_gem5_app.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/serial-getty@.service"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/hpcfund-rocm-hip.cmake"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["scripts/rocm-install.sh"]
  }

  provisioner "file" {
    destination = "/root/roms/"
    source      = "files/mi200.rom"
  }

  provisioner "file" {
    source      = "/home/gem5/vmlinux-gpu-ml"
    destination = "vmlinux-gpu-ml"
    direction   = "download"
  }
}
