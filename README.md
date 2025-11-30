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
![20](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/20.png)`

![21](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/21.png)`

![22](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/22.png)`

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
      ip: 10.20.10.9         
      access_ip: 51.250.86.201
    k8s-worker-1:
      ansible_host: 46.21.245.130
      ip: 10.20.10.14         
      access_ip: 46.21.245.130
    k8s-worker-2:
      ansible_host: 62.84.121.251
      ip: 10.20.20.13         
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
![23](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/23.png)`

8. `Забираю kubeconfig с master-ноды`

```
На локальной машине где запускал Ansible, выполняю:

mkdir -p ~/.kube
ssh ubuntu@51.250.86.201 'sudo cat /etc/kubernetes/admin.conf' > ~/.kube/config  # 51.250.86.201 Ip master-ноды
chmod 600 ~/.kube/config
```

9. `Проверяю кластер прямо на мастер-ноде`ъ

```
1. Подключись к мастеру:
ssh ubuntu@51.250.86.201

2. Переключаюсь в root:
sudo -i

3. Проверяю, что там есть kubeconfig и перекидываю его в ~/.kube/config:

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config

4. Затем 

kubectl get nodes
kubectl get pods --all-namespaces

```
![24](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/24.png)`



10. `Добиваею формулировку «обеспечить доступ к ресурсам из интернета» — сделаю простой nginx через NodePort.`

```
Манифест nginx + NodePort на мастер ноде

cd /root
nano nginx-nodeport.yaml

# Добавляю 


apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-nginx
  template:
    metadata:
      labels:
        app: web-nginx
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-nginx
spec:
  type: NodePort
  selector:
    app: web-nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080

```
12. `Применяю`

```
kubectl apply -f nginx-nodeport.yaml

kubectl get deploy web-nginx
kubectl get svc web-nginx
kubectl get pods -l app=web-nginx -o wide

Открываю в браузере (с любого компьютера с интернетом):
http://51.250.86.201:30080/

http://46.21.245.130:30080/
http://62.84.121.251:30080/

```
![25](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/25.png)`

![26](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/26.png)`




---

### Создание тестового приложения


1. `По заданию создаю пустой рипозиторй для своего приложения`

```
https://github.com/Foxbeerxxx/test-application

Колнирую его на локальную машину и пишу наполнение

test-application/
 ─ nginx.conf
 ─ index.html
 ─ Dockerfile
 ─ README.md
```
2. `nginx.conf`
```
events {}

http {
    server {
        listen 80;
        server_name _;

        # Корневая директория со статикой
        root /usr/share/nginx/html;
        index index.html;

        # Простая health-страница
        location /healthz {
            return 200 'OK';
            add_header Content-Type text/plain;
        }

        # Отдача статики
        location / {
            try_files $uri /index.html;
        }
    }
}

```
3. `index.html`
```
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Test Application</title>
</head>
<body>
    <h1>Test Application для диплома в Yandex Cloud</h1>
    <p>Это статическое приложение на базе Nginx, используемое для проверки деплоя в Kubernetes.</p>
    <p>Версия: v1</p>
</body>
</html>

```

4. `Файл Dockerfile`

```
# Базовый образ с Nginx
FROM nginx:stable-alpine

# Удаляем дефолтный конфиг и кладём свой
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Кладём статический контент
COPY index.html /usr/share/nginx/html/index.html

# HTTP-порт
EXPOSE 80

# Стандартная команда запуска Nginx
CMD ["nginx", "-g", "daemon off;"]

```
5. `README.md`

```
# Test Application

Тестовое приложение для дипломного практикума в Yandex Cloud.

Приложение:
- использует Nginx
- отдаёт статическую страницу `index.html`
- имеет health-endpoint `/healthz`

## Сборка Docker-образа

docker build -t test-application:local .


После создания файлов — коммит и пушь:

bash
git add .
git commit -m "Add nginx-based test application and Dockerfile"
git push origin main

```
6. `В каталоге ~/dz/-Diplom/infra добавляю новый файл, например registry.tf:`

```
resource "yandex_container_registry" "test_registry" {
  name      = "diplom-test-registry"
  folder_id = var.folder_id
}

```
7. `Также каталоге ~/dz/-Diplom/infra в main.tf дописываю`

```
output "container_registry_id" {
  description = "ID Yandex Container Registry для образов приложения"
  value       = yandex_container_registry.test_registry.id
}

```

8. `Далее:`

```
cd ~/dz/-Diplom/infra

terraform init -reconfigure
terraform apply

```
![30](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/30.png)

9. `Логин в Yandex Container Registry`

```
Доступ есть , но можно перестраховаться
yc container registry configure-docker

```
10. `Сборка Docker-образа локально`

```
cd ~/dz/test-application   #  путь, куда я клонировал репозиторий от приложения
docker build -t test-application:v1 .

```
![31](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/31.png)

11. `Тэгирование образа под YCR`

```
docker tag test-application:v1 cr.yandex/crpi9836t83pfjfb81dp/test-application:v1
```
12. `Отправляю в YCR`

```
docker push cr.yandex/crpi9836t83pfjfb81dp/test-application:v1

```
![32](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/32.png)

![33](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/33.png)



### Подготовка cистемы мониторинга и деплой приложения


1. `Захожу на master в YC`
```
ssh ubuntu@89.169.137.143
sudo -i
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
chmod 600 ~/.kube/config
kubectl get nodes
```

2. `Скачиваю kube-prometheus`
```
sudo -i

apt update
apt install -y git curl

cd ~
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus

Команды строго по документации kube-prometheus:
# Шаг 1 — CRD и namespace monitoring
kubectl apply -f manifests/setup/

# Подождать, пока CRD будут созданы
kubectl wait \
  --for=condition=Established \
  --all CustomResourceDefinition

Применить остальные манифесты стека

kubectl apply -f manifests/

Это поставит:
-Prometheus Operator
-Prometheus
-Alertmanager
-Grafana
-kube-state-metrics
-node-exporter
и остальные необходимые компоненты.

Проверка:
kubectl get pods -n monitoring
```
![40](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/40.png)


3. `Деплой тестового приложения (nginx из моего образа в YCR)`
```
Создаю файл /root/test-application.yaml на master:

cat > /root/test-application.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-application
  labels:
    app: test-application
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-application
  template:
    metadata:
      labels:
        app: test-application
    spec:
      containers:
      - name: test-application
        image: cr.yandex/crpi9836t83pfjfb81dp/test-application:v1
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: test-application
spec:
  type: NodePort
  selector:
    app: test-application
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
EOF


Применяю: 
kubectl apply -f /root/test-application.yaml
kubectl get pods -o wide
kubectl get svc

Проверка в браузере (любая нода):
http://84.252.128.124:30080/
http://158.160.38.221:30080/
http://89.169.176.178:30080/

```
![41](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/41.png)

4. `Сделаю Grafana доступной снаружи`

```
На master-ноде:

kubectl -n monitoring patch svc grafana -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http",
        "port": 3000,
        "targetPort": 3000,
        "nodePort": 30300
      }
    ]
  }
}'


Проверить:
kubectl -n monitoring get svc grafana
```
![43](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/43.png)

5. `Сделаю доступным Prometheus`

```
kubectl -n monitoring patch svc prometheus-k8s -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "web",
        "port": 9090,
        "targetPort": 9090,
        "nodePort": 30900
      }
    ]
  }
}'

Проверка:
kubectl -n monitoring get svc prometheus-k8s

из браузера:
http://158.160.38.221:30900
или http://89.169.176.178:30900


```
![42](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/42.png)

![45](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/45.png)


6. ` Grafana все метрики собирает`
![49](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/49.png)

![50](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/50.png)

![51](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/51.png)

7. `Добавляю порты в группу безопастности в ЯОблаке`

```
TCP	30000-32767	CIDR	0.0.0.0/0 app_grafana_prometeus
Any	10250	CIDR	0.0.0.0/0
```


### Деплой инфраструктуры в terraform pipeline

 `Сначало попробовал на основном репозитории Diplom, затем по заданию создал   https://github.com/Foxbeerxxx/ter_in_githubAction  `
1. ` Для работы Terraform в GitHub Actions мне нужно настроить секреты`

```
YC_TOKEN — OAuth-токен/iam-token для провайдера yandex.
YC_OBJ_ACCESS_KEY и YC_OBJ_SECRET_KEY — статический ключ Object Storage (из bootstrap/output):
sa_access_key → YC_OBJ_ACCESS_KEY
sa_secret_key → YC_OBJ_SECRET_KEY
SSH_PUBLIC_KEY —  мой твой публичный ключ  #cat ~/.ssh/id_ed25519.pub

В репозитории:
Открыть: Settings → Secrets and variables → Actions → New repository secret.

```
2. ` Создаю GitHub Actions workflow`

В корне репозитория -Diplom создаю файл:
.github/workflows/terraform-ci.yml

```
name: Terraform CI/CD

on:
  push:
    branches: [ "main" ]
  pull_request:

env:
  TF_IN_AUTOMATION: "true"
  YC_CLOUD_ID: "b1gvjpk4qbrvling8qq1"
  YC_FOLDER_ID: "b1gse67sen06i8u6ri78"
  YC_TOKEN: ${{ secrets.YC_TOKEN }}

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    # тут настраиваем доступ к Object Storage (S3 backend)
    env:
      AWS_ACCESS_KEY_ID:     ${{ secrets.YC_OBJ_ACCESS_KEY }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.YC_OBJ_SECRET_KEY }}
      AWS_DEFAULT_REGION:    "ru-central1"
      TF_VAR_ssh_public_key: ${{ secrets.SSH_PUBLIC_KEY }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.7

      - name: Terraform Init
        working-directory: infra
        run: terraform init -input=false

      - name: Terraform Plan
        working-directory: infra
        run: terraform plan -input=false

      - name: Terraform Apply (only on main)
        if: github.ref == 'refs/heads/main'
        working-directory: infra
        run: terraform apply -auto-approve -input=false

```

3. ` Также сыпались ошибки по infra/backend.tf  поэтому пришлось немного изменить`

```
terraform {
  backend "s3" {
    bucket                      = "tf-state-atata"
    # key                         = "state/terraform.tfstate"
    key    = "infra/terraform.tfstate"
    region                      = "us-east-1"

    endpoint                    = "https://storage.yandexcloud.net"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true

    force_path_style            = true
  }
}

```

4. `Делаю commit & push`

```
Траблшутинг проводил в основном репозитории : https://github.com/Foxbeerxxx/-Diplom

После определения всех проблем и исправление ошибок, вывел в новый репозиторий.
https://github.com/Foxbeerxxx/ter_in_githubAction

```
![47](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/47.png)

![48](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/48.png)



### Установка и настройка CI/CD

1. ` Беру репозиторий с приложением https://github.com/Foxbeerxxx/test-application_v2   для работы с GitHub Action`


2. ` Записываю секреты в GitHub (Settings → Secrets and variables → Actions)`

```
1. YC_REGISTRY_TOKEN  # Outh-токен
2. YC_REGISTRY_ID  # у меня crpi9836t83pfjfb81dp
3. K8S_MASTER_IP   # у меня 84.252.128.124
4. K8S_SSH_KEY  # (~/.ssh/id_ed25519)  

```
![61](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/61.png)


3. `Файл workflow для CI/CD `

```
#   в корень создаю .github/workflows/cicd.yml

name: CI/CD test-application

on:
  push:
    branches:
      - "main"
    tags:
      - "v*.*.*"

env:
  REGISTRY: cr.yandex
  REGISTRY_ID: ${{ secrets.YC_REGISTRY_ID }}
  IMAGE_NAME: test-application

jobs:
  # -------------------------------
  # BUILD & PUSH
  # -------------------------------
  build-and-push:
    name: Build and push image
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set image tag
        run: |
          if [[ "${GITHUB_REF_TYPE}" == "tag" ]]; then
            echo "TAG=${GITHUB_REF_NAME}" >> "$GITHUB_ENV"
          else
            echo "TAG=latest" >> "$GITHUB_ENV"
          fi

      - name: Login to Yandex Container Registry
        env:
          YC_TOKEN: ${{ secrets.YC_TOKEN }}
        run: |
          echo "$YC_TOKEN" | docker login "$REGISTRY" -u oauth --password-stdin

      - name: Build and push image
        run: |
          IMAGE="$REGISTRY/$REGISTRY_ID/$IMAGE_NAME:$TAG"
          echo "Building image: $IMAGE"
          docker build -t "$IMAGE" .
          docker push "$IMAGE"


  # -------------------------------
  # DEPLOY
  # -------------------------------
  deploy:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    needs: build-and-push
    if: startsWith(github.ref, 'refs/tags/')

    steps:
      - name: Add SSH key
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Deploy on k8s master over SSH
        env:
          K8S_MASTER_HOST: ${{ secrets.K8S_MASTER_HOST }}
        run: |
          IMAGE="$REGISTRY/$REGISTRY_ID/$IMAGE_NAME:${GITHUB_REF_NAME}"
          echo "Deploying image: $IMAGE"

          ssh -o StrictHostKeyChecking=no ubuntu@"$K8S_MASTER_HOST" \
            "sudo -i bash -lc ' \
               export KUBECONFIG=/root/.kube/config; \
               kubectl -n default set image deployment/test-application \
                 test-application=$IMAGE; \
               kubectl -n default rollout status deployment/test-application -n default; \
             '"



```

5. `Commit and Push после правка ошибок и все запускается `

![62](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/62.png)

![63](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/63.png)

![64](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/64.png)



6. `Пробую Тегировать и проверка`

```
git tag v5.0.1
git push origin v5.0.1
```
![66](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/66.png)

![65](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/65.png)

![67](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/67.png)


7. ` Перед теированием я поменял в приложении в файлике index.html - версию а именно:`

![68](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/68.png)

8. ` Проверяю, что задеплоилось именно то что нужно, для этого захожу на публичный адрес приложения`

![69](https://github.com/Foxbeerxxx/-Diplom/blob/main/pic/69.png)
