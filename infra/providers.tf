terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    local = {
      source = "hashicorp/local"
    }

    template = {
      source = "hashicorp/template"
    }

    random = {
      source = "hashicorp/random"
    }

    null = {
      source = "hashicorp/null"
    }
  }

  required_version = ">= 1.13.0"

  backend "s3" {
  }

}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("../.authorized_key.json")
}
