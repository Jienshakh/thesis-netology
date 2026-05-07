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

variable "sa_key_file" {
  description = "Path to service account key file"
  type        = string
  default     = null
}

variable "csi_key_file" {
  description = "Path to CSI service account key file"
  type        = string
  default     = null
}


############## NLB Variables ######################

variable "target_group_name" {
  type        = string
  default     = "k8s-ingress-target-group"
  description = "Name of the target group"
}

variable "nlb_name" {
  type        = string
  default     = "k8s-network-load-balancer"
  description = "Network Load Balancer name"
}

variable "http_target_port" {
  type        = number
  default     = 30080
  description = "Target port for HTTP traffic (NodePort of ingress-nginx)"
}

variable "https_target_port" {
  type        = number
  default     = 30081
  description = "Target port for HTTPS traffic (NodePort of ingress-nginx)"
}

variable "nlb_ip_version" {
  type        = string
  default     = "ipv4"
  description = "IP version for external address"
}

variable "healthcheck_name" {
  type        = string
  default     = "http"
  description = "Health check name"
}

variable "healthcheck_healthy_threshold" {
  type        = number
  default     = 2
  description = "Number of successful health checks before target is healthy"
}

variable "healthcheck_unhealthy_threshold" {
  type        = number
  default     = 2
  description = "Number of failed health checks before target is unhealthy"
}

variable "healthcheck_interval" {
  type        = number
  default     = 30
  description = "Interval between health checks in seconds"
}

variable "healthcheck_timeout" {
  type        = number
  default     = 10
  description = "Health check timeout in seconds"
}

variable "healthcheck_port" {
  type        = number
  default     = 30080
  description = "Port for health checks (NodePort HTTP)"
}

variable "healthcheck_path" {
  type        = string
  default     = "/healthz"
  description = "Path for health checks (Ingress controller health endpoint)"
}