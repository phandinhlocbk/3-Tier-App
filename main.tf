#---root/main.tf----


module "networking" {
  source             = "./networking"
  vpc_cidr           = local.vpc_cidrs
  security_groups    = local.security_groups
  access_ip          = var.access_ip
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_cidrs       = ["10.0.1.0/24", "10.0.3.0/24"]
  app_private_cidrs  = ["10.0.2.0/24", "10.0.4.0/24"]
  data_private_cidrs = ["10.0.6.0/24", "10.0.8.0/24"]

}




