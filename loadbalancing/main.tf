# #---loadbalancing/main.tf---

resource "aws_lb" "mtc_lb" {
  name            = "mtc-loadbalancer"
  subnets         = var.public_subnets
  security_groups = [var.public_sg]
  idle_timeout    = 400
}

resource "aws_lb_target_group" "mtc_tg" {
  count    = length(var.target_groups)
  name     = lookup(var.target_groups[count.index], "name", null)
  port     = lookup(var.target_groups[count.index], "backend_port", null)
  protocol = lookup(var.target_groups[count.index], "backend_protocol", null)
  vpc_id   = var.vpc_id
  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
  dynamic "health_check" {
    for_each = [lookup(var.target_groups[count.index], "health_check", {})]
    content {
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      interval            = lookup(health_check.value, "interval", null)

    }
  }
}

locals {
  target_group_attachments = merge(flatten([
    for index, group in var.target_groups : [
      for k, targets in group : {
        for target_key, target in targets : join(".", [index, target_key]) => merge({ tg_index = index }, target)
      }
      if k == "targets"
    ]
  ])...)
}

resource "aws_lb_target_group_attachment" "mtc_lb_tg_attach" {
  for_each = { for k, v in local.target_group_attachments : k => v }

  target_group_arn  = aws_lb_target_group.mtc_tg[each.value.tg_index].arn
  target_id         = each.value.target_id
  port              = lookup(each.value, "port", null)
  availability_zone = lookup(each.value, "availability_zone", null)
}

resource "aws_lb_listener_rule" "mtc_lb_listener" {
  count        = length(var.https_listener_rules)
  listener_arn = aws_lb_listener.mtc_lb_listener[lookup(var.https_listener_rules[count.index], "https_listener_index", count.index)].arn

  dynamic "action" {
    for_each = [
      for action_rule in var.https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "forward"
    ]

    content {
      type             = action.value["type"]
      target_group_arn = aws_lb_target_group.mtc_tg[lookup(action.value, "target_group_index", count.index)].id
    }
  }

  dynamic "condition" {
    for_each = [
      for condition_rule in var.https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }
}

resource "aws_lb_listener" "mtc_lb_listener" {
  count             = length(var.https_listeners)
  load_balancer_arn = aws_lb.mtc_lb.arn
  port              = var.https_listeners[count.index]["port"]
  protocol          = var.https_listeners[count.index]["protocol"]
  certificate_arn   = var.https_listeners[count.index]["certificate_arn"]
  dynamic "default_action" {
    for_each = [var.https_listeners[count.index]]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.mtc_tg[lookup(default_action.value, "target_group_index", count.index)].id
    }
  }
}


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.mtc_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_route53_zone" "mydomain" {
  name = "domainoncloud.com"
}


resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = "apps.domainoncloud.com"
  type    = "A"
  alias {
    name                   = aws_lb.mtc_lb.dns_name
    zone_id                = aws_lb.mtc_lb.zone_id
    evaluate_target_health = true
  }
}