# Shared internal NLB — both blue and green registered. Failover is L4 target
# health (~20s), not Route53 DNS failover.

resource "aws_lb" "ntrip" {
  name_prefix        = "ntrip-"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.nlb_subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.nlb_deletion_protection

  tags = {
    Name = "ntrip-relay-ha-nlb"
  }
}

resource "aws_lb_target_group" "ntrip" {
  name_prefix = "ntrip-"
  port        = local.caster_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = var.nlb_deregistration_delay

  stickiness {
    type    = "source_ip"
    enabled = var.nlb_stickiness
  }

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }

  tags = {
    Name = "ntrip-relay-ha-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.ntrip.arn
  target_id        = module.blue.instance_id
  port             = local.caster_port
}

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.ntrip.arn
  target_id        = module.green.instance_id
  port             = local.caster_port
}

resource "aws_lb_listener" "ntrip" {
  load_balancer_arn = aws_lb.ntrip.arn
  port              = local.caster_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ntrip.arn
  }
}
