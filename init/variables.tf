############## Common vars ################
variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "sa_name" {
  type        = string
  default     = "sa-thesis"
  description = "service account name"
}

variable "sa_k8s_name" {
  type        = string
  description = "Name of SA for Kubernetes infra"
  default     = "k8s-sa"
}

############# Storage variables #################

variable "lab_bucket_size" {
  type        = number
  default     = 10485760
  description = "backet max size"
}