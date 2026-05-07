terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

  }
  required_version = "~>1.13.0"

  backend "local" {
    path = "init.tfstate"
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  
  # Используем переменную, если она задана
  service_account_key_file = var.service_account_key_file != "" ? var.service_account_key_file : null
}