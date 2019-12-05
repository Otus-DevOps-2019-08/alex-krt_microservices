# alex-krt_microservices
alex-krt microservices repository

# Домашняя работа - Docker контейнеры. Docker под капотом.

Создание docker host, работа с Docker образами и контейнерами, работа с Docker Hub

## Задание со *

Поднятие инстансов с помощью Terraform

Файл main.tf

```
terraform {
  required_version = "0.12.8"
}

provider "google" {
  version = "2.15"
  project = var.project
  region = var.region
}

resource "google_compute_instance" "docker-app" {
  name = "reddit-app-docker"
  machine_type = "g1-small"
  zone = "europe-west1-b"
  tags = ["docker"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
    }
  count = var.instances_count

  network_interface {
    network = "default"
    access_config{}
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  network = "default"
  allow {
    protocol = "tcp" 
    ports = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["docker"]
}
```

Количество инстансов задается с помощью переменной var.instances_count

```
count = var.instances_count
```

Плейбуки ansible:

Плейбук для установки Docker docker.yml

```
---
- name: Install docker
  hosts: reddit
  become: true
  tasks:
    - name: Install dependencies
      apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg-agent
          - software-properties-common
    - name: Add docker gpg key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present
    - name: Add docker repo
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu bionic stable
        state: present
    - name: Update apt and install docker-ce
      apt: update_cache=yes name=docker-ce state=latest
```

Плейбук для загрузки и запуска нашего образа app.yml

```
---
- name: Start Docker image reddit
  hosts: reddit
  become: true
  tasks:
    - name: Install pip
      apt:
        name: python-pip
        update_cache: yes

    - name: Install Docker SDK for python
      pip:
        name: docker

    - name: Start container
      docker_container:
        name: reddit
        image: zhmoorik/otus-reddit:1.0
        ports:
          - "9292:9292"
```
Динамический инвентори (файл inventory.gcp.yml)

```
plugin: gcp_compute
projects:
  - docker-***
auth_kind: serviceaccount
service_account_file: ~/Documents/docker-***.json
groups:
  reddit: "'reddit' in name"
```

Шаблон пакера для создания образа с установленным докером

```
{
    "variables" : {
        "project_id":null,
        "source_image_family":null,
        "machine_type":"f1-micro",
        "image_description":null,
        "disk_size":null,
        "disk_type":null,
        "network":null
    },
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{ user `project_id`}}",
            "image_name": "reddit-app-docker-{{timestamp}}",
            "image_family": "reddit-app-docker",
            "source_image_family": "{{ user `source_image_family` }}",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "{{ user `machine_type` }}"
        }
    ],
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/docker.yml"
        }
    ]
}
```

# Домашняя работа - Docker образы, микросервисы

Разбитие приложение на микросервисы, работа с docker образами и их запуск

# Домашняя работа - Сетевое взаимодействие Docker контейнеров. Docker Compose. Тестирование образов

Для того, чтобы использовать несколько сетей, как в примере, необходимо в docker-compose.yml указать названия сетей, тип bridge и подсети:

```
networks:
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
```

И после этого в описании сервисов указать название нужной сети:

```
services:
  post_db:
    image: mongo:${MONGO_VER}
# Здесь указывается имя контейнера
    container_name: mongo_db
    volumes:
      - post_db:/data/db
    networks:
      back_net:
# А здесь алиасы сетей
        aliases:
          - post_db
          - comment_db
```

Для того, чтобы изменить базовое имя проекта, необходимо указать переменную среды COMPOSE_PROJECT_NAME, можно в файле .env
Сам не проверял, но должно работать)))

# Домашняя работа - Устройство Gitlab CI. Построение процесса непрерывной интеграции

В ходе домашней работы развернул на виртуальной машине в google cloud gitlab-ci с помощью docker.
Работа с приложением reddit, построение пайплайна и описание окружений.
