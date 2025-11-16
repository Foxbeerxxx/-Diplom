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

6. `Ключи доступа к бакету S3`

```
terraform output -raw sa_access_key    # bootstrap создаёт бакет tf-state-atata и выдаёт к нему ключи
terraform output -raw sa_secret_key

Дальше экспортирую ключи

export AWS_ACCESS_KEY_ID="$(terraform output -raw sa_access_key)"
export AWS_SECRET_ACCESS_KEY="$(terraform output -raw sa_secret_key)"
export AWS_DEFAULT_REGION="ru-central1"

cd ~/dz/-Diplom/bootstrap
terraform apply

```

`В Папке infra`


5. `main.tf`

```


```


`При необходимости прикрепитe сюда скриншоты
![Название скриншота 1](ссылка на скриншот 1)`


---

### Задание 2

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
