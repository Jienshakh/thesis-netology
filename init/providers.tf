terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    random = {
      source = "hashicorp/random"
    }

    local = {
      source = "hashicorp/local"
    }
  }

  required_version = ">= 1.13.0"

  backend "local" {
    path = "init.tfstate"
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("~/.authorized_key.json")
}