#---root/main.tf----


module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidrs
  public_sn_count  = 2
  private_sn_count = 2
  max_subnets      = 20
  security_groups  = local.security_groups
  access_ip        = var.access_ip
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidrs, 8, i)]
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidrs, 8, i)]
  db_subnet_group  = true

}


module "compute_app1" {
  depends_on         = [module.networking]
  source             = "./compute"
  instance_count_app = 2
  instance_type      = "t3.micro"
  instance_sg        = module.networking.private_sg
  instance_subnets   = module.networking.private_subnets
  keyname            = "terraform-key-1"
  user_data_app      = file("${path.module}/install/app1-install.sh")
  vol_size           = 10
  instance_name      = "compute_app1"
}
module "compute_app2" {
  depends_on         = [module.networking]
  source             = "./compute"
  instance_count_app = 2
  instance_type      = "t3.micro"
  instance_sg        = module.networking.private_sg
  instance_subnets   = module.networking.private_subnets
  keyname            = "terraform-key-1"
  user_data_app      = file("${path.module}/install/app2-install.sh")
  vol_size           = 10
  instance_name      = "compute_app2"
}

module "compute_app3" {
  depends_on         = [module.networking]
  source             = "./compute"
  instance_count_app = 2
  instance_type      = "t3.micro"
  instance_sg        = module.networking.private_sg
  instance_subnets   = module.networking.private_subnets
  keyname            = "terraform-key-1"
  user_data_app      = templatefile("install/app3-ums-install.tmpl", { rds_db_endpoint = module.database.db_instance_address })
  vol_size           = 10
  instance_name      = "compute_app3"
}



module "bastion_host" {
  source             = "./compute"
  instance_count_app = 1
  instance_type      = "t3.micro"
  instance_sg        = module.networking.bastion_sg
  instance_subnets   = module.networking.bastion_subnets
  keyname            = "terraform-key-1"
  user_data_app      = file("${path.module}/install/jumpbox-install.sh")
  vol_size           = 10
  instance_name      = "bastion_host"
}

module "loadbalancing" {
  source         = "./loadbalancing"
  public_sg      = module.networking.public_sg
  public_subnets = module.networking.public_subnets
  vpc_id         = module.networking.vpc_id


  target_groups = [
    #App1 Target Group
    {
      name             = "app1"
      backend_protocol = "HTTP"
      backend_port     = 80
      health_check = {
        interval            = 30
        path                = "/app1/index.html"
        port                = "80"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
      }

      targets = {
        my_ec2 = {
          target_id = module.compute_app1.instance_app_id[0]
          port      = 80
        },
        my_ec2_again = {
          target_id = module.compute_app1.instance_app_id[1]
          port      = 80
        }
      }
    },
    #App2 Target Group
    {
      name             = "app2"
      backend_protocol = "HTTP"
      backend_port     = 80
      health_check = {
        interval            = 30
        path                = "/app2/index.html"
        port                = "80"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
      }

      targets = {
        my_ec2 = {
          target_id = module.compute_app2.instance_app_id[0]
          port      = 80
        },
        my_ec2_again = {
          target_id = module.compute_app2.instance_app_id[1]
          port      = 80
        }
      }
    },
    #App3 Target Group
    {
      name             = "app3"
      backend_protocol = "HTTP"
      backend_port     = 80
      health_check = {
        interval            = 30
        path                = "/login"
        port                = "80"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
      }

      targets = {
        my_ec2 = {
          target_id = module.compute_app3.instance_app_id[0]
          port      = 80
        },
        my_ec2_again = {
          target_id = module.compute_app3.instance_app_id[1]
          port      = 80
        }
      }
    }

  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = "arn:aws:acm:us-east-1:*******:certificate/26458b43-3ffa-4041-96f0-c78d8ac8842b"
      target_group_index = 1
    },
  ]
  https_listener_rules = [
    # Rule-1: /app1* should go to App1 EC2 Instances
    {
      https_listener_index = 0
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        path_patterns = ["/app1*"]
      }]
    },
    # Rule-2: /app2* should go to App2 EC2 Instances    
    {
      https_listener_index = 0
      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]
      conditions = [{
        path_patterns = ["/app2*"]
      }]
    },
    # Rule-2: /app2* should go to App3 EC2 Instances    
    {
      https_listener_index = 0
      actions = [
        {
          type               = "forward"
          target_group_index = 2
        }
      ]
      conditions = [{
        path_patterns = ["/*"]
      }]
    },
  ]


}

module "database" {
  source                 = "./database"
  db_engine              = "mysql"
  db_storage             = 20
  db_engine_version      = "8.0.20"
  db_instance_class      = "db.t2.micro"
  dbname                 = var.dbname
  dbusername             = var.dbusername
  dbpassword             = var.dbpassword
  db_subnet_group_name   = module.networking.mtc_rds_subnet_group
  vpc_security_group_ids = module.networking.rds_sg
  db_identifier          = "mtc-db"
  db_skip_final_snapshot = true
}

module "autoscaling" {
  source        = "./autoscaling"
  aws_ami_id    = module.compute_app2.aws_ami_id
  instance_type = "t3.micro"
  private_sg_id = [module.networking.private_sg]
  key_name      = "terraform-key-1"
  user_data_app = filebase64("${path.module}/install/app1-install.sh")

  private_subnet_id    = module.networking.private_subnets
  alb_target_group_arn = module.loadbalancing.alb_target_group_arn[0]

  alb_dns_prefix = "${module.loadbalancing.aws_lb_arn}/${module.loadbalancing.aws_lb_prefix[0]}"
}




