#--networking/variables.tf----
variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_cidrs" {
  type = list(string)
}

variable "app_private_cidrs" {
  type = list(string)
}

variable "data_private_cidrs" {
  type = list(string)
}

variable "access_ip" {
  type = string
}

variable "security_groups" {}

