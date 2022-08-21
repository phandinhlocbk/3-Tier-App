#--loadbalancing/variables.tf---

variable "public_sg" {}
variable "public_subnets" {}
variable "vpc_id" {}
variable "target_groups" {
  type    = any
  default = []
}
variable "https_listener_rules" {
  type    = any
  default = []
}
variable "https_listeners" {
  type    = any
  default = []
}