###### Create SA for working with infrastructure

resource "yandex_iam_service_account" "sa_thesis" {
  name        = var.sa_name
  description = "SA for infra"
  folder_id   = var.folder_id
}

#### Assigning SA Roles

locals {
  roles = [
    "storage.admin",
    "compute.admin",
    "vpc.admin",
    "editor",
    "vpc.publicAdmin",
    "load-balancer.admin"
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "sa_roles" {
  for_each = toset(local.roles)

  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.sa_thesis.id}"
}

###### Create SA for Kubernetes infrastructure

resource "yandex_iam_service_account" "sa_k8s" {
  name        = var.sa_k8s_name
  description = "SA for k8s CSI driver"
  folder_id   = var.folder_id
}

#### Assigning SA Role

resource "yandex_resourcemanager_folder_iam_member" "sa_k8s_compute_editor" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa_k8s.id}"
}

#### Create bucket 

# To always have a unique bucket name
resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "yandex_storage_bucket" "tfstate_bucket" {
  bucket   = "tfstate-${random_string.unique_id.result}"
  max_size = var.lab_bucket_size
  folder_id  = var.folder_id
}

## Create static keys for infra SA

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa_thesis.id
  description = "static access key for object storage"
}

### Create a new IAM Service Account Key.

resource "yandex_iam_service_account_key" "sa-auth-key" {
  service_account_id =  yandex_iam_service_account.sa_thesis.id
  description        = "key for service account"
  key_algorithm      = "RSA_4096"
}

resource "local_sensitive_file" "sa_private_key" {
  filename = "../.authorized_key.json"
  content = jsonencode({
  id                 = yandex_iam_service_account_key.sa-auth-key.id
  service_account_id = yandex_iam_service_account_key.sa-auth-key.service_account_id
  created_at         = yandex_iam_service_account_key.sa-auth-key.created_at
  key_algorithm      = yandex_iam_service_account_key.sa-auth-key.key_algorithm
  public_key         = yandex_iam_service_account_key.sa-auth-key.public_key
  private_key        = yandex_iam_service_account_key.sa-auth-key.private_key
  })
}

## Create static access key for K8s SA

resource "yandex_iam_service_account_static_access_key" "sa_k8s_static_key" {
  service_account_id = yandex_iam_service_account.sa_k8s.id
  description        = "static access key for k8s SA"
}

### Create IAM Service Account Key

resource "yandex_iam_service_account_key" "sa_k8s_auth_key" {
  service_account_id = yandex_iam_service_account.sa_k8s.id
  description        = "auth key for k8s service account"
  key_algorithm      = "RSA_4096"
}

resource "local_sensitive_file" "sa_k8s_private_key" {
  filename = "../k8s/CSI/.authorized_key.json"

  content = jsonencode({
    id                 = yandex_iam_service_account_key.sa_k8s_auth_key.id
    service_account_id = yandex_iam_service_account_key.sa_k8s_auth_key.service_account_id
    created_at         = yandex_iam_service_account_key.sa_k8s_auth_key.created_at
    key_algorithm      = yandex_iam_service_account_key.sa_k8s_auth_key.key_algorithm
    public_key         = yandex_iam_service_account_key.sa_k8s_auth_key.public_key
    private_key        = yandex_iam_service_account_key.sa_k8s_auth_key.private_key
  })
}