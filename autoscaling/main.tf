#---autoscaling/main.terraform---
resource "aws_launch_template" "app_launch_template" {
  name          = "app1-launch-template"
  description   = "Launch Template"
  image_id      = var.aws_ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.private_sg_id
  key_name               = var.key_name
  user_data              = var.user_data_app
  ebs_optimized          = true

  update_default_version = true
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size         = 20
      volume_type         = "gp2"
    }
  }
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "appasg"
    }
  }
}


#Autoscaling Group Resource
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 10
  min_size            = 2
  vpc_zone_identifier = var.private_subnet_id
  target_group_arns   = [var.alb_target_group_arn]
  health_check_type = "EC2"
  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = aws_launch_template.app_launch_template.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = [ "desired_capacity" ]
  }
  tag {
    key                 = "Owners"
    value               = "Web-Team"
    propagate_at_launch = true
  }
}

#SNS topic
resource "aws_sns_topic" "asg_sns_topic" {
  name = "aasg-sns-topic"
}
#SNS subscription
resource "aws_sns_topic_subscription" "myasg_sns_topic_subscription" {
  topic_arn = aws_sns_topic.asg_sns_topic.arn
  protocol  = "email"
  endpoint  = "phandinhlocbk@gmail.com"
}

#Create Autoscaling Notification Resource
resource "aws_autoscaling_notification" "asg_notification" {
  group_names = [aws_autoscaling_group.app_asg.id]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.asg_sns_topic.arn
}

#Autoscaling Policies
resource "aws_autoscaling_policy" "avg_cpu" {
  name                      = "avg-cpu"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.app_asg.id
  estimated_instance_warmup = 180
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

#ALB Request
resource "aws_autoscaling_policy" "alb_request" {
  name                      = "alb-request"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.app_asg.id
  estimated_instance_warmup = 180
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_dns_prefix
    }
    target_value = 50
  }
}

