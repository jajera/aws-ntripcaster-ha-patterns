# Network Load Balancer (layer 4 TCP passthrough) in front of the caster.
#
# Why NLB and not ALB: NTRIP streams are long-lived and NTRIP v1 is not
# HTTP-compliant. An ALB buffers and expects request/response HTTP, which breaks
# streaming. The NLB forwards raw TCP.
#
# Health check is TCP, not HTTP: the caster only speaks HTTP/1.1 when the client
# sends an "Ntrip-Version" header, and NLB health checks cannot set custom
# headers. A plain GET returns no HTTP status line, so an HTTP check would mark
# every target permanently unhealthy. TCP connect is the correct probe.

resource "aws_lb" "ntripcaster" {
  count = var.enable_nlb ? 1 : 0

  name_prefix        = "ntrip-"
  internal           = var.nlb_internal
  load_balancer_type = "network"
  subnets            = var.nlb_subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.nlb_deletion_protection

  tags = {
    Name = "${var.name_prefix}-nlb"
  }

  lifecycle {
    precondition {
      condition     = length(var.nlb_subnet_ids) > 0
      error_message = "Set nlb_subnet_ids when enable_nlb is true."
    }
  }
}

resource "aws_lb_target_group" "ntripcaster" {
  count = var.enable_nlb ? 1 : 0

  name_prefix = "ntrip-"
  port        = var.caster_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Long-lived streams: do not reap idle-looking connections early.
  deregistration_delay = var.nlb_deregistration_delay

  # NTRIP clients reconnect to the same caster; keep them pinned so a client does
  # not bounce between casters mid-stream once a second node exists.
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
    Name = "${var.name_prefix}-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "ntripcaster" {
  count = var.enable_nlb ? 1 : 0

  target_group_arn = aws_lb_target_group.ntripcaster[0].arn
  target_id        = aws_instance.ntripcaster.id
  port             = var.caster_port
}

resource "aws_lb_listener" "ntripcaster" {
  count = var.enable_nlb ? 1 : 0

  load_balancer_arn = aws_lb.ntripcaster[0].arn
  port              = var.caster_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ntripcaster[0].arn
  }
}
