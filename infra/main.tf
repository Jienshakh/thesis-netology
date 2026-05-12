module "k8s-network" {
  source       = "./modules/vpc"
  env_name     = "k8s"
  subnets = [
    { zone = "ru-central1-a", cidr = "10.0.1.0/24" },
    { zone = "ru-central1-b", cidr = "10.0.2.0/24" },
    { zone = "ru-central1-d", cidr = "10.0.3.0/24" },
  ]
}

data "template_file" "cloudinit" {
  template = file("./cloud-init.yaml")
  
  vars = {
    username           = var.username
    ssh_public_key     = var.ssh_public_key
    packages           = jsonencode(var.packages)
  }
}

module "k8s_master" {
  source          = "git::https://github.com/jienshakh/yandex_compute_instance.git?ref=main"
  env_name        = "k8s" 
  network_id      = module.k8s-network.network_id
  subnet_zones    = module.k8s-network.subnet_zones
  subnet_ids      = module.k8s-network.subnet_ids
  instance_name   = "master"
  instance_count  = 1
  instance_cores  = 2 
  instance_memory = 4
  boot_disk_size  = 20
  instance_core_fraction = 20
  image_family    = "ubuntu-2404-lts"
  public_ip       = false

  labels = { 
    project = "k8s"
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered #Для демонстрации №3
    serial-port-enable = 1
  }
}

module "k8s_worker" {
  source          = "git::https://github.com/jienshakh/yandex_compute_instance.git?ref=main"
  env_name        = "k8s" 
  network_id      = module.k8s-network.network_id
  subnet_zones    = module.k8s-network.subnet_zones
  subnet_ids      = module.k8s-network.subnet_ids
  instance_name   = "worker"
  instance_count  = 3
  instance_cores  = 4
  boot_disk_size  = 30
  instance_memory = 6
  instance_core_fraction = 20
  image_family    = "ubuntu-2404-lts" 
  public_ip       = true

  labels = { 
    project = "k8s"
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered #Для демонстрации №3
    serial-port-enable = 1
  }
}

#######  NLB #######

resource "yandex_lb_target_group" "k8s_nodes" {
  name      = var.target_group_name
  folder_id = var.folder_id

  dynamic "target" {
    for_each = module.k8s_worker.network_interface
    content {
      subnet_id = target.value[0].subnet_id
      address   = target.value[0].ip_address
    }
  }
}


resource "yandex_lb_network_load_balancer" "k8s_nlb" {
  name      = var.nlb_name
  folder_id = var.folder_id

  listener {
    name = "http-listener"
    port = 80
    target_port = var.http_target_port
    external_address_spec {
      ip_version = var.nlb_ip_version
    }
  }

  listener {
    name = "https-listener"
    port = 443
    target_port = var.https_target_port
    external_address_spec {
      ip_version = var.nlb_ip_version
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s_nodes.id

    healthcheck {
      name                = var.healthcheck_name
      healthy_threshold   = var.healthcheck_healthy_threshold
      unhealthy_threshold = var.healthcheck_unhealthy_threshold
      interval            = var.healthcheck_interval
      timeout             = var.healthcheck_timeout
      
      http_options {
        port = var.healthcheck_port
        path = var.healthcheck_path
      }
    }
  }
}

### Generate ConfigMap for CSI

resource "local_file" "yc_csi_config" {
  content = templatefile("../k8s/CSI/yc-csi-config.yaml.tpl", {
    folder_id = var.folder_id
  })

  filename = "../k8s/CSI/manifests/yc-csi-config.yaml"
}

### Generate Secret for CSI

locals {
  sa_key_base64 = filebase64("../k8s/CSI/.authorized_key.json")
}

resource "local_file" "yc_csi_secret" {
  content = templatefile("../k8s/CSI/secret.yaml.tpl", {
    sa_key_json = local.sa_key_base64
  })

  filename = "../k8s/CSI/manifests/secret.yaml"
}