terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.99"
    }
  }
  required_version = ">= 1.5.0"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# VPC + две подсети в разных зонах
resource "yandex_vpc_network" "main" {
  name = "diplom-network"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.20.0/24"]
}

# Образ Ubuntu 22.04
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

locals {
  k8s_nodes = {
    "k8s-master-1" = {
      subnet_id   = yandex_vpc_subnet.subnet_a.id
      zone        = "ru-central1-a"
      preemptible = false   # master не прерываемый
    }
    "k8s-worker-1" = {
      subnet_id   = yandex_vpc_subnet.subnet_a.id
      zone        = "ru-central1-a"
      preemptible = true    # worker прерываемый
    }
    "k8s-worker-2" = {
      subnet_id   = yandex_vpc_subnet.subnet_b.id
      zone        = "ru-central1-b"
      preemptible = true    # worker прерываемый
    }
  }
}


resource "yandex_compute_instance" "k8s" {
  for_each = local.k8s_nodes

  name        = each.key
  hostname    = each.key
  platform_id = "standard-v2"   # можно поменять при необходимости
  zone        = each.value.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20          # минимизируем долю CPU
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = each.value.subnet_id
    nat       = true            # публичный IP для доступа и Ansible
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

output "k8s_nodes_public_ips" {
  value = {
    for name, inst in yandex_compute_instance.k8s :
    name => inst.network_interface[0].nat_ip_address
  }
}

output "k8s_master_public_ip" {
  value = yandex_compute_instance.k8s["k8s-master-1"].network_interface[0].nat_ip_address
}
