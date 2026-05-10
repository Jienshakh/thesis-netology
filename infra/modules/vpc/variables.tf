variable "subnets" {
  type     = list(object({
    zone = string
    cidr = string
  }))
}

variable "env_name" {
  type = string
}

variable "route_table_name" {
  description = "Name of the routing table"
  type        = string
  default     = "my-rt"
}

variable "destination_prefix" {
  description = "Destination CIDR prefix for the static route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "gateway_name" {
  description = "Name of the NAT gateway"
  type        = string
  default     = "my-nat-gateway"
}