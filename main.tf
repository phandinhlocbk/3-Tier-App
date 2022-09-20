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

module "compute_app" {
  depends_on         = [module.networking]
  source             = "./compute"
  instance_count_app = 2
  instance_type      = "t2.micro"
  instance_sg        = module.networking.private_sg
  instance_subnets   = module.networking.private_subnets
  keyname            = "terraform-key-1"
  user_data_app      = file("${path.module}/install/app-install.sh")
  vol_size           = 10
  instance_name      = "compute_app"
}

module "bastion_host" {
  depends_on         = [module.networking]
  source             = "./compute"
  instance_count_app = 1
  instance_type      = "t2.micro"
  instance_sg        = module.networking.bastion_sg
  instance_subnets   = module.networking.bastion_subnets
  keyname            = "terraform-key-1"
  user_data_app      = file("${path.module}/install/jumpbox-install.sh")
  vol_size           = 10
  instance_name      = "bastion_host"
}




