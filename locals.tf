#---root/locals.tf---

locals {
  vpc_cidrs = "10.0.0.0/16"
}

locals {
  security_groups = {
    public = {
      name        = "public_sg"
      description = "public sg"
      ingress = {
        ssh = {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        http = {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        https = {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }

      }
    }

    rds = {
      name        = "rds_sg"
      description = "rds sg"
      ingress = {
        mysql = {
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidrs]
        }
      }
    }

    bastion = {
      name        = "basion_sg"
      description = "bastion sg"
      ingress = {
        ssh = {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [var.my_ip]
        }
      }
    }

    private = {
      name        = "private_sg"
      description = "private sg"
      ingress = {
        ssh = {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidrs]
        }
        http = {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidrs]
        }
        https = {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidrs]
        }
      }
    }
  }
}

