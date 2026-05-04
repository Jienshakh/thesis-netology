variable "subnets" {
  type     = list(object({
    zone = string
    cidr = string
  }))
}

variable "env_name" {
  type = string
}

