resource "yandex_vpc_network" "vpc_network" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "vpc_subnet" {
  for_each       = local.subnets_map
  name           = "${var.env_name}-${each.value.zone}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.vpc_network.id
  v4_cidr_blocks = [each.value.cidr]
}

