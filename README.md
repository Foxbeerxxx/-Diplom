# Домашнее задание к занятию "`Дипломный практикум в Yandex.Cloud`" - `Татаринцев Алексей`




### Создание облачной инфраструктуры

1. `Авторизация YC  через токен`

```
yc init
авторизуюсь по outh токену : y0__xCT0uf65RMggtW4jxOf2sKmFlatvU579i7Vgfw   # написал здесь не настоящий
```
2. `Создаю новый токен доступа к ресурсам,так как предыдущий уже "протух" и экспортирую в среду`

```
export YC_TOKEN=$(yc iam create-token)
и проверяю
echo $YC_TOKEN
```
`В Папке bootstrap`
3. `Пишу main.tf` 

```
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


resource "yandex_iam_service_account_static_access_key" "tf_key" {
  service_account_id = yandex_iam_service_account.tf_sa.id
}

resource "yandex_storage_bucket" "tf_state" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  versioning {
    enabled = true
  }
}

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

output "sa_access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf_key.secret_key
  sensitive = true
}


```
4. `Пишу variables.tf`

```
variable "cloud_id" {
  type    = string
  default = "b1gvjpk4qbrvling8qq1"
}

variable "folder_id" {
  type    = string
  default = "b1gse67sen06i8u6ri78"
}

variable "bucket_name" {
  type    = string
  default = "tf-state-atata"
}

```

5. `Затем пробую запустить стартовую конфигурацию terraform apply`

```
terraform 
terraform apply

```
![1](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img1.png)`

6. `Ключи доступа к бакету S3`

```
terraform output -raw sa_access_key    # bootstrap создаёт бакет tf-state-atata и выдаёт к нему ключи
terraform output -raw sa_secret_key

Дальше экспортирую ключи

export AWS_ACCESS_KEY_ID="$(terraform output -raw sa_access_key)"
export AWS_SECRET_ACCESS_KEY="$(terraform output -raw sa_secret_key)"
export AWS_DEFAULT_REGION="ru-central1"



```

`В Папке infra`


7. `main.tf`

```
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


```
8. `variables.tf`

```
variable "cloud_id" {
  type    = string
  default = "b1gvjpk4qbrvling8qq1"
}

variable "folder_id" {
  type    = string
  default = "b1gse67sen06i8u6ri78"
}
```


9. `backend.tf`

```
terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "tf-state-atata"
    key    = "infra/terraform.tfstate"
    region = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

```

10. `Переходим  в папку infra и запускаю`

```
cd ~/dz/-Diplom/infra
terraform init -reconfigure
terraform apply
```

![2](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img2.png)`

![3](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img3.png)`

![5](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img5.png)`

![4](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img4.png)`



---

### Создание Kubernetes кластера



1. `В infra/variables.tf добавляю переменную для SSH-ключа`

```
variable "cloud_id" {
  type    = string
  default = "b1gvjpk4qbrvling8qq1"
}

variable "folder_id" {
  type    = string
  default = "b1gse67sen06i8u6ri78"
}

variable "ssh_public_key" {
  description = "SSH public key for user ubuntu"
  type        = string
}


```




2. `В infra/main.tf: дополняю конфигурацию`

```
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


# Это создаст:

# 1 master (k8s-master-1, не прерываемый),
# 2 worker’а (k8s-worker-1, k8s-worker-2, прерываемые),
# все с публичными IP, маленькие по ресурсу (2 vCPU, 4GB, 20% core_fraction).

```

3. `Обновляю токен и ключи`

```
cd ~/dz/-Diplom/bootstrap

export YC_TOKEN=$(yc iam create-token)
export AWS_ACCESS_KEY_ID=$(terraform output -raw sa_access_key)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw sa_secret_key)
export AWS_DEFAULT_REGION="ru-central1"

cd ~/dz/-Diplom/infra

terraform init -reconfigure

```

4. `В infra перед apply подставляем SSH-ключ:`

```
cd ~/dz/-Diplom/infra
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)" 

terraform apply

# В результате будут созданы 3 ВМ, backend уже работает, стейт — в бакете
```

5. `Развёртывание Kubernetes через Kubespray`

```
Дальше — Ansible/Kubespray. Логика такая:

1. С локальной машины подключаюсь по SSH к узлам.
2. Kubespray ставит кластер поверх этих 3 ВМ.
3. В ~/.kube/config появится доступ к кластеру.
```
![20](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img20.png)`

![21](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img21.png)`

![22](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/img22.png)`

6. `Установка Kubespray (на локальной машине)`

```
curl -L -o kubespray.zip https://github.com/kubernetes-sigs/kubespray/archive/refs/heads/master.zip
unzip kubespray.zip
mv kubespray-master kubespray
cd kubespray

# Создаю virtualenv и устанавливаем зависимости

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Создаю inventory для кластера

cp -rfp inventory/sample inventory/diplom-cluster

# Правлю hosts.yaml

nano inventory/diplom-cluster/hosts.yaml


###########################################
all:
  hosts:
    k8s-master-1:
      ansible_host: 51.250.86.201
      ip: 10.20.10.9          # ← как в ошибке
      access_ip: 51.250.86.201
    k8s-worker-1:
      ansible_host: 46.21.245.130
      ip: 10.20.10.14         # ← как в ошибке
      access_ip: 46.21.245.130
    k8s-worker-2:
      ansible_host: 62.84.121.251
      ip: 10.20.20.13         # ← как в ошибке
      access_ip: 62.84.121.251

  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: /home/alexey/.ssh/id_ed25519

  children:
    kube_control_plane:
      hosts:
        k8s-master-1:
    kube_node:
      hosts:
        k8s-worker-1:
        k8s-worker-2:
    etcd:
      hosts:
        k8s-master-1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}


```

7. `Запускаю Kubespray`


```
cd ~/kubespray
source venv/bin/activate
ansible-playbook -i inventory/diplom-cluster/hosts.yaml cluster.yml -b -v
```


8. ``
9. ``
10. ``

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота 2](ссылка на скриншот 2)`


---

### Задание 3

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`

### Задание 4

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`
