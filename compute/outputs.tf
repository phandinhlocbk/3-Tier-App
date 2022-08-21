#--compute/outputs.tf---
output "instance_app_id" {
  value = aws_instance.mtc_node_app.*.id
}

# output "instance_app_id_2" {
#   value = aws_instance.mtc_node_app.*.id[1]
# }
output "bastion_ip" {
  value = aws_instance.mtc_node_app.*.public_ip
}

output "aws_ami_id" {
  value = data.aws_ami.amzlinux2.id
}

