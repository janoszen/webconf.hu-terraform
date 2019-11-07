variable "exoscale_key" {}
variable "exoscale_secret" {}
variable "exoscale_zone" {
  default = "at-vie-1"
}

variable "server_hostname" {
  default = "webconf"
}
variable "server_domain" {
  default = "hu"
}

variable "ssh_port" {
  default = 12222
}


variable "instance_type" {
  default = "Micro"
}

variable "disk_size" {
  default = 10
}

variable "users" {
  type = map(string)
}

locals {
  domain_name = "${var.server_hostname}.${var.server_domain}"
}
variable "container_version" {
  default = "master-SNAPSHOT"
}