#--networking/main.tf----

resource "random_integer" "random" {
  min = 1
  max = 100
}

data "aws_availability_zones" "available" {}

resource "random_shuffle" "az_lists" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "mtc_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Name = "mtc_vpc-${random_integer.random.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_lists.result[count.index]
  tags = {
    Name = "mtc_public_${count.index + 1}"
  }
}

resource "aws_subnet" "mtc_private_subnet" {
  count             = var.private_sn_count
  vpc_id            = aws_vpc.mtc_vpc.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = random_shuffle.az_lists.result[count.index]
  tags = {
    Name = "mtc_private_${count.index}"
  }
}

#---internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    Name = "mtc-igw"
  }
}

#---public route table---
resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "mtc_public_rt"
  }
}

resource "aws_route" "mtc_public_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "mtc_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.mtc_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.mtc_public_rt.id

}
#----natgateway-route table----
resource "aws_route_table" "mtc_nat_rt" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    Name = "mtc_nat_rt"
  }
}

resource "aws_route" "mtc_nat_route" {
  route_table_id         = aws_route_table.mtc_nat_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mtc_natgw.id
}

resource "aws_route_table_association" "mtc_nat_assoc" {
  count          = var.private_sn_count
  subnet_id      = aws_subnet.mtc_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.mtc_nat_rt.id
}


#---private route table----
resource "aws_default_route_table" "mtc_private_rt" {
  default_route_table_id = aws_vpc.mtc_vpc.default_route_table_id

  tags = {
    Name = "mtc_private_rt"

  }
}

#--security group---

resource "aws_security_group" "mtc_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.mtc_vpc.id
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
resource "aws_nat_gateway" "mtc_natgw" {
  subnet_id     = aws_subnet.mtc_public_subnet[1].id
  allocation_id = aws_eip.nat_eip.id
  tags = {
    Name = "mtc-natgw"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat_eip"
  }

}

#---subnet group rds ---
resource "aws_db_subnet_group" "mtc_rds_subnet_group" {
  // count      = var.db_subnet_group == true ? 1 : 0
  name = "mtc_subnet_group"
  subnet_ids = [aws_subnet.mtc_private_subnet.*.id[0],
  aws_subnet.mtc_private_subnet.*.id[1]]
  tags = {
    Name = "mtc_rds_sng"
  }
}