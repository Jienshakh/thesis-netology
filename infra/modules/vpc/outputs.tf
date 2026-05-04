output "network_id" {
  value = yandex_vpc_network.vpc_network.id
}

output "subnet_ids" {
  value = [ for subnet in yandex_vpc_subnet.vpc_subnet : subnet.id]
}

output "subnet_zones" {
  value = [ for subnet in yandex_vpc_subnet.vpc_subnet : subnet.zone]
}




