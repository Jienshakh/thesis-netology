#!/bin/bash

### Запускаем проект для создания SA, назначения ролей SA, создания бакета, получение access_key, secret_key для доступа к бакету

terraform -chdir=init init
terraform -chdir=init apply -auto-approve

### Получаем output'ы в JSON

outputs=$(terraform -chdir=init output -json)

### Извлекаем значения
bucket=$(echo $outputs | jq -r .bucket_name.value)
access_key=$(echo $outputs | jq -r .access_key.value)
secret_key=$(echo $outputs | jq -r .secret_key.value)
key=$(echo $outputs | jq -r .key.value)
endpoint=$(echo $outputs | jq -r .endpoint.value)
region=$(echo $outputs | jq -r .region.value)

### Создаём backend.tfbackend для infra

cat > ./backend.tfbackend <<EOF
bucket = "$bucket"
access_key = "$access_key"
secret_key = "$secret_key"
key = "$key"
endpoint = "$endpoint"
region = "$region"
skip_requesting_account_id = true
skip_region_validation = true
skip_credentials_validation = true
EOF

### Запускаем infra

terraform -chdir=infra init -backend-config=../backend.tfbackend
terraform -chdir=infra apply -auto-approve

### Гененируем inventory для kubespray

terraform -chdir=infra  output -raw inventory > inventory/k8s/inventory.ini

### Гененирурем ingress для Grafana с адресом NLB

export nlb_ip=$(terraform -chdir=infra output -raw nlb_ip)
envsubst < k8s/monitoring/grafana-ingress.yaml.tpl > k8s/monitoring/overlays/grafana-ingress.yaml

### Гененрируем ingress для тестового приложения с адресом NLB

export nlb_ip=$(terraform -chdir=infra output -raw nlb_ip)
envsubst < k8s/app/ingress.yaml.tpl > k8s/app/manifests/ingress.yaml

### Гененрируем ingress для atlantis с адресом NLB

export nlb_ip=$(terraform -chdir=infra output -raw nlb_ip)
envsubst < k8s/CSI/ingress.yaml.tpl > k8s/CSI/manifests/ingress.yaml