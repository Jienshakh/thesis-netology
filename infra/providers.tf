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

resource "local_file" "sa_key_temp" {
  count  = var.sa_key_json != "" ? 1 : 0
  content = var.sa_key_json
  filename = "/tmp/sa_key.json"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
  
  service_account_key_file = var.sa_key_json != "" ? local_file.sa_key_temp[0].filename : var.sa_key_file
}
