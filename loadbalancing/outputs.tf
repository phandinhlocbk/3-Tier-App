#---loadbalancing/outputs.tf
output "alb_target_group_arn" {
  value = aws_lb_target_group.mtc_tg.*.id
}

output "aws_lb_arn" {
  value = aws_lb.mtc_lb.arn_suffix
}

output "aws_lb_prefix" {
  value = aws_lb_target_group.mtc_tg.*.arn_suffix
}

