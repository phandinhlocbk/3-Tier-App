#---compute/main.tf---
#Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
#-----private instance----

resource "aws_instance" "task_node_app" {

  count         = var.instance_count_app #2
  instance_type = var.instance_type      #t2.micro
  ami           = data.aws_ami.amzlinux2.id
  tags = {
    Name = "task-node-${var.instance_name}-${count.index}"
  }
  vpc_security_group_ids = [var.instance_sg]
  subnet_id              = var.instance_subnets[count.index]
  key_name               = var.keyname
  user_data              = var.user_data_app
  root_block_device {
    volume_size = var.vol_size
  }
}




