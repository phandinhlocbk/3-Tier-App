#--compute/variables.tf---
variable "instance_count_app" {
  type = number
}
variable "instance_type" {}
variable "instance_sg" {}
variable "instance_subnets" {}
variable "keyname" {}
variable "user_data_app" {}
variable "vol_size" {}
variable "instance_name" {}


