output "bucket_name" {
  description = "S3 bucket name for Terraform state backend"
  value       = yandex_storage_bucket.tfstate_bucket.bucket
}

output "access_key" {
  description = "Static access key for SA"
  value       = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}

output "secret_key" {
  description = "Static secret key for SA"
  value       = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}

output "key" {
  description = "Path to state file in bucket"
  value       = "infra/terraform.tfstate"
}

output "endpoint" {
  description = "Yandex Cloud S3 endpoint"
  value       = "https://storage.yandexcloud.net"
}

output "region" {
  description = "Yandex Cloud region"
  value       = "ru-central1"
}

