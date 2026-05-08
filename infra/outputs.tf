output "inventory" {
  value = templatefile("inventory.tmpl", {
    master_public_ips = module.k8s_master.external_ip_address
    master_private_ips = module.k8s_master.internal_ip_address
    worker_public_ips = module.k8s_worker.external_ip_address
    worker_private_ips = module.k8s_worker.internal_ip_address
  })
}

output "nlb_ip" {
  value = flatten([
    for l in yandex_lb_network_load_balancer.k8s_nlb.listener :
    [
      for addr in l.external_address_spec :
      addr.address
    ]
  ])[0]
}

output "ssh_public_key" {
  description = "SSH public key for VM access"
  value       = var.ssh_public_key
  sensitive   = true
}

output "username" {
  description = "Default VM username"
  value       = var.username
}