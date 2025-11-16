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

# 1. Сервисный аккаунт для Terraform
resource "yandex_iam_service_account" "tf_sa" {
  name = "terraform-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "tf_sa_vpc" {
  folder_id = var.folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "tf_sa_compute" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "tf_sa_storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tf_sa.id}"
}

# Статический ключ для Object Storage
resource "yandex_iam_service_account_static_access_key" "tf_key" {
  service_account_id = yandex_iam_service_account.tf_sa.id
}

# 2. Бакет под стейт
resource "yandex_storage_bucket" "tf_state" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  versioning {
    enabled = true
  }
}

output "sa_access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf_key.secret_key
  sensitive = true
}
