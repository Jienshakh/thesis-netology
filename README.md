## Подготовительные работы

### 1. Создание управляющей ВМ в Яндекс.Облаке

В том же каталоге, где будет разворачиваться основная инфраструктура, создать виртуальную машину для управления (bastion/control-host).

**Параметры ВМ:**
- ОС: Ubuntu 24.04 LTS
- vCPU: 2
- RAM: 4 ГБ
- Диск: 15 ГБ HDD
- Гарантированная доля vCPU 20%
- Прерываемая
- Публичный IP: назначен

**Результат:**
Получен IP-адрес для подключения по SSH. Дальнейшая работа с Terraform, Kubespray и kubectl выполняется с этой ВМ.

### 2. Установка Yandex Cloud CLI и аутентификация на виртуальной машине для управления

```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```
После установки перезапустите консоль.

Для Ubuntu Server без графического интерфейса необходимо открыть ссылку из вывода команды

```bash
yc init
```
на локальном устройстве, авторизоваться в Яндекс ID, получить OAuth-токен и вставить его в терминал на сервере.
Создайте каталог, если он ещё не создан.
Дефолтную зону выбирать необязательно.

### 3. Установка и настройка Terraform на виртуальной машине для управления

- Скачать архив с [официального сайта Terraform](https://developer.hashicorp.com/terraform/install)
- Бинарный файл `terraform` поместить в одну из директорий переменной PATH.
- Создать файл `.terraformrc` в домашней директории пользователя со следующим содержимым:

```hcl
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
Примечание: Я использовал версию 1.13.5

### 4. Создание сервисного аккаунта (SA) согласно [инструкции](https://yandex.cloud/ru/docs/iam/operations/sa/create).
- Создаётся сервисный аккаунт (промежуточный), который будет использоваться для последующего создания основного сервисного аккаунта через Terraform. Данный аккаунт применяется однократно и не используется в основной инфраструктуре.
```bash
yc iam service-account create --name <имя_сервисного_аккаунта>
```

### 5. Назначение роли сервисному аккаунту согласно [инструкции](https://yandex.cloud/ru/docs/iam/operations/sa/assign-role-for-sa).
```bash
yc resource-manager folder add-access-binding \
  --id <идентификатор_каталога> \
  --role editor \
  --service-account-name <имя_сервисного_аккаунта>
```
### 6. Создание авторизованного ключа `.authorized_key.json`

```bash
yc iam key create --service-account-name <имя_сервисного_аккаунта> --output .authorized_key.json
```
### 7. Сгенерировать пару ключей для подключения по ssh

```bash
ssh-keygen -t ed25519 -C "control-vm" -f ~/.ssh/id_ed25519
```

### 8. Клонирование репозитория с конфигурациями

```bash
git clone https://github.com/Jienshakh/thesis-netology.git
cd thesis-netology
```

Репозиторий содержит:

- init/ - Terraform конфигурации для создания sa и бакета
- infra/ - Terraform конфигурации для создания инфраструктуры
- inventory/ - инвентори и файлы конфигурации для Kubespray
- k8s/ - манифесты Kubernetes (часть гененрируется terraform из templates)
- .github/workflows/ - workflow для Github Action
- run.sh - скрипт для развёртывания
- update_inventory.sh - скрипт обновления инвентори
- create_action_secrets_file.sh - скрипт для создания секретов в Github для работы workflow

### 9. Создание файлов с переменными

В директории `init/` и `infra/` необходимо создать файлы `personal.auto.tfvars` с персональными значениями.

**Для `init/personal.auto.tfvars`:**
```hcl
cloud_id  = "<ваш_cloud_id>"
folder_id = "<ваш_folder_id>"
```

**Для `infra/personal.auto.tfvars`:**

```hcl
cloud_id       = "<ваш_cloud_id>"
folder_id      = "<ваш_folder_id>"
ssh_public_key = <<-EOF
<содержимое файла ~/.ssh/id_ed25519.pub>
EOF
username       = "ubuntu"
```
Как получить values:

- `cloud_id и folder_id` — выполнить `yc config list` или посмотреть в консоли Яндекс.Облака
- `ssh_public_key` — содержимое файла `~/.ssh/id_ed25519.pub`

## Создание облачной инфраструктуры. Terraform

Для автоматизации создания инфраструктуры используется shell-скрипт `run.sh`, расположенный в корне репозитория проекта:  
[thesis-netology](https://github.com/Jienshakh/thesis-netology)

Скопируйте репозиторий на созданную ранее ВМ:

```bash
git clone https://github.com/Jienshakh/thesis-netology.git
```

### Назначение скрипта `run.sh`

Скрипт выполняет полный цикл подготовки и развёртывания инфраструктуры:

1. Создание сервисного аккаунта и S3 backend для Terraform state
2. Получение output-переменных Terraform
3. Генерация файла `backend.tfbackend`
4. Инициализация и применение основной Terraform-конфигурации
5. Генерация inventory для Kubespray
6. Генерация ingress-манифестов Kubernetes

### Запуск Terraform

Перед запуском необходимо перейти в корень репозитория и выдать права на выполнение:

```bash
chmod +x run.sh
```

Запуск:

```bash
./run.sh
```

### Создание backend для Terraform

На первом этапе используется конфигурация из каталога `init/`.

Выполняются команды:

```bash
terraform -chdir=init init
terraform -chdir=init apply -auto-approve
```

В результате создаются:

- сервисный аккаунт Terraform
- сервисный аккаунт для 
- S3 bucket для хранения Terraform state
- access_key и secret_key для доступа к backend

### Генерация backend-конфигурации

После получения Terraform outputs автоматически создаётся файл `backend.tfbackend`, содержащий параметры подключения к S3 backend.

Пример содержимого:

```bash
bucket = "<bucket_name>"
access_key = "<access_key>"
secret_key = "<secret_key>"
key = "<key>"
endpoint = "<endpoint>"
region = "<region>"
```

### Разворачивание основной инфраструктуры

После подготовки backend запускается конфигурация из каталога `infra/`.

Выполняются команды:

```bash
terraform -chdir=infra init -backend-config=../backend.tfbackend
terraform -chdir=infra plan
terraform -chdir=infra apply -auto-approve
```

В результате создаются:
- VPC
- подсети
- виртуальные машины
- Network Load Balancer
- инфраструктура Kubernetes-кластера

### Генерация inventory для Kubespray

После создания виртуальных машин автоматически формируется inventory-файл:

```bash
terraform -chdir=infra output -raw inventory > inventory/k8s/inventory.ini
```

Полученный inventory используется для последующего развёртывания Kubernetes через Kubespray.

### Генерация ingress-манифестов

Скрипт также автоматически генерирует ingress-манифесты с использованием IP-адреса Network Load Balancer.

Генерируются ingress:

- Grafana
- тестового приложения
- Gitlab


Для генерации используется утилита `envsubst`.

### Назначение Network Load Balancer и схема доступа к Kubernetes

В рамках инфраструктуры создаётся Network Load Balancer (NLB) в Yandex Cloud.

NLB используется как единая точка входа во внешний контур Kubernetes-кластера и обеспечивает доступ к ingress-controller (nginx ingress controller), развернутому в кластере.

### Схема маршрутизации трафика

Архитектура входящего трафика реализована следующим образом:

```text
внешний трафик → Network Load Balancer (Yandex Cloud) → нода Kubernetes (hostPort 80/443) → nginx ingress controller → сервисы внутри Kubernetes → Pod’ы
```

### Использование nip.io для доменных имён

Так как в проекте не используется собственный домен, применяется сервис nip.io, который позволяет формировать DNS-имена на основе IP-адреса.

Пример:

```text
grafana.103.76.54.202.nip.io
```

Где:

- `103.76.54.202` — публичный IP-адрес Network Load Balancer;
- `nip.io` — wildcard DNS сервис;
- `grafana` — имя сервиса, определённое в Ingress.

### Генерация ingress-манифестов

IP-адрес Network Load Balancer становится известен только после создания инфраструктуры, поэтому ingress-манифесты формируются автоматически на этапе Terraform pipeline.

Это позволяет:

- автоматически подставлять актуальный IP;
- исключить ручное редактирование DNS-имен;
- обеспечить доступ к сервисам через единый внешний endpoint;
- сохранить воспроизводимость инфраструктуры.


## Создание Kubernetes кластера. Kubespray

После того как инфраструктура развернута, приступаем к созданию self-hosted Kubernetes-кластера с помощью Kubespray.

В процессе реализации возникла проблема с сетевой связанностью между хостами. Виртуальные машины Kubernetes-кластера используют отдельную VPC-сеть `k8s`, тогда как ранее созданная `control-vm` находится в другой VPC-сети (`default`, если собственная сеть не создавалась).

Между разными VPC в Yandex Cloud отсутствует приватная сетевая связанность, а простого способа организовать её не предусмотрено. Поэтому помимо master-ноды и worker-нод был создан дополнительный хост `k8s-control-0`, размещённый в той же VPC-сети, что и Kubernetes-кластер.

С этой виртуальной машины будет:
- выполняться разворачивание Kubernetes-кластера через Kubespray;
- применяться Kubernetes-манифесты;
- использоваться `kubectl` для управления кластером.

> Примечание: существует альтернативный вариант — назначить всем узлам Kubernetes-кластера публичные IP-адреса. В этом случае `control-vm` сможет подключаться к ним напрямую. Однако при таком подходе в Yandex Cloud можно столкнуться с внутренним ограничением на скорость создания публичных IP-адресов.

Пример ошибки:

```text
Error: Error while waiting operation to create instance: operation (id=<id>) failed: rpc error: code = ResourceExhausted desc = RESOURCE_EXHAUSTED: Quota limit vpc.externalAddressesCreation.rate exceeded
```

Ошибка не связана с исчерпанием квоты на количество публичных IP-адресов. Ограничение касается именно скорости их создания и отсутствует в официальной документации Yandex Cloud.

Ответ технической поддержки Yandex Cloud:

```
Это внутреннее ограничение сервиса [VPC](https://yandex.cloud/ru/docs/vpc/) на создание [публичных IP-адресов](https://yandex.cloud/ru/docs/vpc/concepts/address#public-addresses). Это ограничение не отображается на странице квот и в документации, с нашей стороны размер лимита и время его действия подсказать не получится.
Попробуйте, пожалуйста, повторить попытку создания [ВМ](https://yandex.cloud/ru/docs/glossary/vm) с публичным IP-адресом позже.
Чтобы реже сталкиваться с этим ограничением, рекомендуем по возможности создавать виртуальные машины без публичных IP-адресов.
Если ВМ нужен исходящий доступ в интернет, вместо назначения публичного IP-адреса каждой машине можно использовать NAT-шлюз. Инструкция по настройке NAT-шлюза доступна в нашей [документации](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).
```


#### Создание Kubernetes-кластера

1. Скопировать с `control-vm` на `k8s-control-0` директории `inventory` и `k8s`:

```bash
scp -r scp -r inventory/ k8s/ ubuntu@<публичный_ip_k8s-control-0>:~
```

2. Скопировать приватный SSH-ключ на k8s-control-0, чтобы Ansible мог подключаться к узлам кластера:

```bash
scp ~/.ssh/id_ed25519 ubuntu@<публичный_ip_k8s-control-0>:~/.ssh
```

3. Подключиться к k8s-control-0:

```bash
ssh ubuntu@<публичный_ip_k8s-control-0>
```

4. Terraform автоматически сгенерировал inventory-файл для Ansible. Так как используются приватные IP-адреса, которые обычно не изменяются после перезагрузки ВМ, дополнительная настройка inventory не требуется. 
Перед запуском Kubespray можно проверить доступность SSH-подключения между хостами.
В официальной документации Kubespray описаны несколько вариантов запуска (Docker, Ansible, Vagrant). В данной работе используется вариант с Docker.

На `k8s-control-0` выполнить:

```bash
docker run --rm -it \
  --mount type=bind,source="$(pwd)"/inventory/k8s,dst=/inventory \
  --mount type=bind,source="${HOME}"/.ssh/id_ed25519,dst=/root/.ssh/id_ed25519 \
  quay.io/kubespray/kubespray:v2.30.0 bash
```

5. Внутри Docker-контейнера выполнить запуск playbook:

```bash
ansible-playbook -i /inventory/inventory.ini \
  --private-key /root/.ssh/id_ed25519 \
  --become \
  cluster.yml
```
6. Настроить `kubectl` для работы с кластером.

После успешного выполнения playbook и создания Kubernetes-кластера в директории `inventory/k8s/artifacts/` будут автоматически сгенерированы:
- `admin.conf` — kubeconfig для подключения к кластеру;
- `kubectl` — бинарный файл клиента Kubernetes;
- `kubectl.sh` — вспомогательный скрипт для работы с кластером.

Для удобства настроим `kubectl` напрямую на хосте `k8s-control-0`:

```bash
mkdir -p ~/.kube
sudo cp inventory/k8s/artifacts/admin.conf ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
chmod 600 ~/.kube/config
sudo mv inventory/k8s/artifacts/kubectl /usr/local/bin/
kubectl get pods -A
```

После выполнения команды kubectl get pods -A должен отобразиться список pod'ов всех namespace Kubernetes-кластера.

Кластер готов к работе.

## Интерактивный терминальный интерфейс `k9s`

Для удобства работы с Kubernetes-кластером можно установить интерактивный терминальный интерфейс `k9s`.

Установка:

```bash
curl -LO https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_linux_amd64.deb
sudo dpkg -i k9s_linux_amd64.deb
```

Запуск:

```bash
k9s
```

## Создание тестового приложения

Для тестирования CI/CD-процессов и последующего деплоя в Kubernetes-кластер было подготовлено простое тестовое приложение на базе Nginx.

Исходный код приложения размещён в отдельном Git-репозитории:  
[thesis-test-app](https://github.com/Jienshakh/thesis-test-app)

### Состав приложения

Репозиторий содержит:
- `Dockerfile` — описание сборки Docker-образа;
- `nginx.conf` — конфигурацию Nginx;
- статический контент, отдаваемый web-сервером.

### Dockerfile

Для сборки приложения используется Docker-образ Nginx.
Сборка выполняется с помощью следующего Dockerfile:

```dockerfile
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html/index.html /usr/share/nginx/html/index.html
```
### Сборка Docker-образа

Сборка образа:

```bash
docker build -t thesis-test-app:v0.1 .
```

### Публикация образа

После сборки Docker-образ был опубликован в container registry и в дальнейшем используется для деплоя в Kubernetes-кластер.
Пример тегирования и отправки образа:

```
docker tag thesis-test-app:v0.1 <registry>/<repository>:v0.1
docker push <registry>/<repository>:v0.1
```

### Результат

Подготовлено тестовое приложение:

- с отдельным Git-репозиторием;
- Dockerfile для автоматической сборки образа;
- Docker-образом, готовым для использования в Kubernetes и CI/CD pipeline.

## Подготовка системы мониторинга

После создания Kubernetes-кластера необходимо развернуть систему мониторинга.

Для мониторинга используется `kube-prometheus`, который включает:
- Prometheus;
- Grafana;
- Alertmanager;
- kube-state-metrics;
- node-exporter;
- Prometheus Operator.

Конфигурационные файлы мониторинга расположены в директории:

```text
k8s/monitoring
```

### Структура каталогов

| Каталог | Назначение |
|---|---|
| `base/setup` | CRD ресурсы Prometheus Operator и namespace monitoring |
| `base` | Основные манифесты kube-prometheus |
| `overlays` | Дополнительные манифесты и настройки |
| `grafana-ingress.yaml.tpl` | Шаблон ingress для Grafana |

### Состав системы мониторинга

В состав kube-prometheus входят следующие компоненты:

- `Prometheus` — сбор и хранение метрик;
- `Grafana` — визуализация метрик и дашборды;
- `Alertmanager` — обработка алертов;
- `node-exporter` — метрики узлов Kubernetes;
- `kube-state-metrics` — метрики ресурсов Kubernetes;
- `Prometheus Operator` — управление ресурсами мониторинга.

### Установка kube-prometheus

Сначала необходимо создать CRD ресурсы Prometheus Operator:

```bash
kubectl apply --server-side -f k8s/monitoring/base/setup/
```

После этого применяются основные манифесты мониторинга:

```bash
kubectl apply -f k8s/monitoring/base/
```

Затем применяются дополнительные манифесты:

```bash
kubectl apply -f k8s/monitoring/overlays/
```

### Настройка доступа к Grafana

Для доступа к Grafana используется ingress-манифест `grafana-ingress.yaml`.

Манифест создаётся из шаблона `grafana-ingress.yaml.tpl` с подстановкой IP-адреса Network Load Balancer.

Применение ingress:

```bash
kubectl apply -f k8s/monitoring/overlays/grafana-ingress.yaml
```

### Проверка состояния компонентов

Проверка pod'ов системы мониторинга:

```bash
kubectl get pods -n monitoring
```

Проверка ingress:

```bash
kubectl get ingress -n monitoring
```

### Результат

В Kubernetes-кластере развернута система мониторинга на базе kube-prometheus.

Grafana доступна через Ingress и Network Load Balancer.

## Деплой инфраструктуры в terraform pipeline

