#---networking/outputs.tf----
output "vpc_id" {
  value = aws_vpc.mtc_vpc.id
}

output "internet_gw" {
  value = aws_internet_gateway.igw.id
}

output "public_sg" {
  value = aws_security_group.mtc_sg["public"].id

}

output "private_sg" {
  value = aws_security_group.mtc_sg["private"].id

}
output "rds_sg" {
  value = [aws_security_group.mtc_sg["rds"].id]

}

output "bastion_sg" {
  value = aws_security_group.mtc_sg["bastion"].id

}

output "private_subnets" {
  value = aws_subnet.mtc_private_subnet.*.id
}

output "public_subnets" {
  value = aws_subnet.mtc_public_subnet.*.id
}

output "bastion_subnets" {
  value = aws_subnet.mtc_public_subnet.*.id
}

output "mtc_rds_subnet_group" {
  value = aws_db_subnet_group.mtc_rds_subnet_group.name
}