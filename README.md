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

Так как управляющая ВМ не имеет графического интерфейса, аутентификация выполняется с использованием OAuth-токена:

```bash
yc init
```
полученную ссылку вставьте в адресную строку браузера, скопируйте полученный код верификации и вставьте в консоль (предварительно необходимо залогиниться в облаке). 
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