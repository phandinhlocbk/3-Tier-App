#variables.terraform 
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "access_ip" {
  type    = string
  default = "0.0.0.0/0"
}
#---database variable -----
variable "dbname" {
  type = string
}
variable "dbusername" {
  type      = string
  sensitive = true
}
variable "dbpassword" {
  type      = string
  sensitive = true
}