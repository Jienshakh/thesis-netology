resource "yandex_vpc_network" "vpc_network" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "vpc_subnet" {
  for_each       = local.subnets_map
  name           = "${var.env_name}-${each.value.zone}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.vpc_network.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = yandex_vpc_route_table.my_route_table.id
}

resource "yandex_vpc_gateway" "my_nat_gw" {
  name = var.gateway_name
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "my_route_table" {
  name       = var.route_table_name
  network_id = yandex_vpc_network.vpc_network.id

  static_route {
    # Весь трафик в интернет (0.0.0.0/0) пойдёт через шлюз
    destination_prefix = var.destination_prefix
    gateway_id         = yandex_vpc_gateway.my_nat_gw.id
  }
}
