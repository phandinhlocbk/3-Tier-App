#variables.terraform 
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "access_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "my_ip" {
  type    = string
  default = "0.0.0.0/0"
}
