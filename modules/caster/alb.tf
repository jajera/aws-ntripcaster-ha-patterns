# Application Load Balancer for HTTP admin UI (+ optional Prometheus).
#
# NTRIP clients stay on the NLB (L4). This ALB is HTTP-only and locked down to
# admin_cidr_blocks. ALB nodes become the TCP source IP at the caster, so
# allow admin includes the VPC CIDR when this is enabled (SG is the real gate).

locals {
  admin_alb_subnet_ids = length(var.admin_alb_subnet_ids) > 0 ? var.admin_alb_subnet_ids : var.nlb_subnet_ids
  enable_prometheus    = var.enable_admin_alb && var.enable_prometheus
}

resource "aws_security_group" "admin_alb" {
  count = var.enable_admin_alb ? 1 : 0

  name_prefix = "${var.name_prefix}-admin-alb-"
  description = "Admin ALB - ingress from admin_cidr_blocks only"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Admin UI"
      from_port   = var.admin_alb_port
      to_port     = var.admin_alb_port
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = local.enable_prometheus && length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Prometheus UI"
      from_port   = var.prometheus_port
      to_port     = var.prometheus_port
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  egress {
    description = "To caster targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = {
    Name = "${var.name_prefix}-admin-alb"
  }

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = length(var.admin_cidr_blocks) > 0
      error_message = "enable_admin_alb requires admin_cidr_blocks."
    }
    precondition {
      condition     = length(local.admin_alb_subnet_ids) > 0
      error_message = "Set admin_alb_subnet_ids (or nlb_subnet_ids) when enable_admin_alb is true."
    }
  }
}

resource "aws_lb" "admin" {
  count = var.enable_admin_alb ? 1 : 0

  name_prefix        = "nadm-"
  internal           = var.admin_alb_internal
  load_balancer_type = "application"
  subnets            = local.admin_alb_subnet_ids
  security_groups    = [aws_security_group.admin_alb[0].id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-admin-alb"
  }
}

# --- Admin UI → caster :2101 -------------------------------------------------

resource "aws_lb_target_group" "admin" {
  count = var.enable_admin_alb ? 1 : 0

  name_prefix = "nadm-"
  port        = var.caster_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Plain GET / has no HTTP status (Ntrip needs Ntrip-Version). /admin without
  # credentials returns 401 — treat that as healthy.
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/admin"
    port                = "traffic-port"
    matcher             = "401"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.name_prefix}-admin-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "admin" {
  count = var.enable_admin_alb ? 1 : 0

  target_group_arn = aws_lb_target_group.admin[0].arn
  target_id        = aws_instance.ntripcaster.id
  port             = var.caster_port
}

resource "aws_lb_listener" "admin" {
  count = var.enable_admin_alb ? 1 : 0

  load_balancer_arn = aws_lb.admin[0].arn
  port              = var.admin_alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin[0].arn
  }
}

# --- Prometheus → host :9090 -------------------------------------------------

resource "aws_lb_target_group" "prometheus" {
  count = local.enable_prometheus ? 1 : 0

  name_prefix = "nprom-"
  port        = var.prometheus_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/-/healthy"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.name_prefix}-prom-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "prometheus" {
  count = local.enable_prometheus ? 1 : 0

  target_group_arn = aws_lb_target_group.prometheus[0].arn
  target_id        = aws_instance.ntripcaster.id
  port             = var.prometheus_port
}

resource "aws_lb_listener" "prometheus" {
  count = local.enable_prometheus ? 1 : 0

  load_balancer_arn = aws_lb.admin[0].arn
  port              = var.prometheus_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus[0].arn
  }
}

# Opening http://alb:9090/ lands on a graph already querying the caster.
# Prometheus 2.x UI path is /graph ( /query is 3.x only ).
resource "aws_lb_listener_rule" "prometheus_default_graph" {
  count = local.enable_prometheus ? 1 : 0

  listener_arn = aws_lb_listener.prometheus[0].arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type = "redirect"
    redirect {
      path        = "/graph"
      port        = "#{port}"
      protocol    = "#{protocol}"
      query       = "g0.expr=caster_connected_sources&g0.tab=0&g0.range_input=15m"
      status_code = "HTTP_302"
    }
  }
}
