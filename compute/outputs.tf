#--compute/outputs.tf---
output "instance_app_id" {
  value = aws_instance.task_node_app.*.id
}

output "bastion_ip" {
  value = aws_instance.task_node_app.*.public_ip
}