terraform {
  required_version = ">= 1.5.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "rssb" {
  name = "rssb"
  type = "dir"
  path = "/var/lib/libvirt/images/rssb"
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu22.04-base.qcow2"
  source = "/home/sdragon/libvirt-images/ubuntu22.04-base.qcow2"
  pool   = libvirt_pool.rssb.name
}

resource "libvirt_network" "k8s_network" {
  name      = "rssb-network"
  mode      = "nat"
  addresses = ["10.17.3.0/24"]
  dhcp { enabled = true }
}

resource "libvirt_volume" "master_disk" {
  name           = "master.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = libvirt_pool.rssb.name
  size           = 10737418240
}

resource "libvirt_cloudinit_disk" "master_cloudinit" {
  name      = "master-cloudinit.iso"
  user_data = templatefile("cloudinit/master.cfg", {
    hostname = "rssb-master"
    ssh_key  = file("~/.ssh/rssb_project.pub")
  })
  pool = libvirt_pool.rssb.name
}

resource "libvirt_domain" "master" {
  name   = "rssb-master"
  memory = "2048"
  vcpu   = 2
  cloudinit = libvirt_cloudinit_disk.master_cloudinit.id
  network_interface {
    network_id = libvirt_network.k8s_network.id
  }
  disk { volume_id = libvirt_volume.master_disk.id }
}

resource "libvirt_volume" "worker_disk" {
  count  = 2
  name   = "worker-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool   = libvirt_pool.rssb.name
  size   = 10737418240
}

resource "libvirt_cloudinit_disk" "worker_cloudinit" {
  count = 2
  name  = "worker-${count.index}-cloudinit.iso"
  user_data = templatefile("cloudinit/worker.cfg", {
    hostname = "rssb-worker-${count.index}"
    ssh_key  = file("~/.ssh/rssb_project.pub")
  })
  pool = libvirt_pool.rssb.name
}

resource "libvirt_domain" "worker" {
  count  = 2
  name   = "rssb-worker-${count.index}"
  memory = "2048"
  vcpu   = 2
  cloudinit = libvirt_cloudinit_disk.worker_cloudinit[count.index].id
  network_interface {
    network_id = libvirt_network.k8s_network.id
  }
  disk { volume_id = libvirt_volume.worker_disk[count.index].id }
}

output "master_ip" {
  value = "10.17.3.10"
}

output "worker_ips" {
  value = ["10.17.3.11", "10.17.3.12"]
}
