###common vars

variable "username" {
  type = string
}

variable "ssh_public_key" {
  type        = string
  description = "Location of SSH public key."
}

variable packages {
  type    = list
  default = [
    "vim",
    "nginx"
  ]
}
