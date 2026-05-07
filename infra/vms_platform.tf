###common vars

variable "username" {
  type = string
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content"
}

variable packages {
  type    = list
  default = [
    "vim",
    "nginx"
  ]
}
