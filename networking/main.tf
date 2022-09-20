#--networking/main.tf----


resource "aws_vpc" "task_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mtc-vpc-task"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "task_public_subnet" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.task_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags = {
    Name = "task-public-${count.index + 1}"
  }
}

resource "aws_subnet" "task_app_private_subnet" {
  count             = length(var.app_private_cidrs)
  vpc_id            = aws_vpc.task_vpc.id
  cidr_block        = var.app_private_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "task-app-private-${count.index + 1}"
  }
}

resource "aws_subnet" "task_data_private_subnet" {
  count             = length(var.data_private_cidrs)
  vpc_id            = aws_vpc.task_vpc.id
  cidr_block        = var.data_private_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "task-data-private-${count.index + 1}"
  }
}

#---internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.task_vpc.id
  tags = {
    Name = "task-igw"
  }
}

#---public route table---
resource "aws_route_table" "task_public_rt" {
  vpc_id = aws_vpc.task_vpc.id

  tags = {
    Name = "task-public-rt"
  }
}

resource "aws_route" "task_public_route" {
  route_table_id         = aws_route_table.task_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "task_public_assoc" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.task_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.task_public_rt.id

}
#----natgateway-route table----
resource "aws_route_table" "task_nat_rt" {
  vpc_id = aws_vpc.task_vpc.id
  tags = {
    Name = "task-nat-rt"
  }
}

resource "aws_route" "task_nat_route" {
  route_table_id         = aws_route_table.task_nat_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.task_natgw.id
}

resource "aws_route_table_association" "mtc_nat_assoc" {
  count          = length(var.app_private_cidrs)
  subnet_id      = aws_subnet.task_app_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.task_nat_rt.id
}

#--security group---

resource "aws_security_group" "task_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.task_vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    description = "Allow All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#---nat gateway----
resource "aws_nat_gateway" "task_natgw" {
  subnet_id     = aws_subnet.task_public_subnet[1].id
  allocation_id = aws_eip.nat_eip.id
  tags = {
    Name = "task-natgw"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat-eip"
  }
}

#---subnet group rds ---
resource "aws_db_subnet_group" "task_rds_subnet_group" {
  name = "mtc-subnet-group"
  subnet_ids = [aws_subnet.task_data_private_subnet.*.id[0],
  aws_subnet.task_data_private_subnet.*.id[1]]
  tags = {
    Name = "mtc-rds-sng"
  }
}