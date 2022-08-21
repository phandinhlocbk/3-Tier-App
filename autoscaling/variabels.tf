#---autoscaling/variables.tf---
variable "aws_ami_id" {}
variable "instance_type" {}
variable "private_sg_id" {}
variable "key_name" {}
variable "user_data_app" {}

#Autoscaling group
variable "private_subnet_id" {}
variable "alb_target_group_arn" {}

#ALB Request
variable "alb_dns_prefix" {}
