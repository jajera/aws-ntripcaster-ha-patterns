data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# CIDR used to allow NLB health checks, which come from within the VPC.
data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "random_password" "oper" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "random_password" "encoder" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "aws_security_group" "ntripcaster" {
  name_prefix = "${var.name_prefix}-"
  description = "NtripCaster ingest on TCP 2101"
  vpc_id      = var.vpc_id

  # No ingest ingress: the caster relay-pulls from the receiver (outbound, via
  # egress below). Admin UI is either direct admin_cidr_blocks, SSM, or the
  # admin ALB (preferred).
  dynamic "ingress" {
    for_each = local.nlb_ingress_enabled && length(var.nlb_client_cidr_blocks) > 0 ? [1] : []
    content {
      # An instance-target NLB preserves the client source IP, so this rule must
      # list the real client CIDRs — not the NLB or its subnets.
      description = "NTRIP client traffic via NLB (source IP preserved)"
      from_port   = var.caster_port
      to_port     = var.caster_port
      protocol    = "tcp"
      cidr_blocks = var.nlb_client_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = local.nlb_ingress_enabled ? [1] : []
    content {
      # NLB health checks originate from the VPC-internal subnet addresses.
      description = "NLB TCP health check"
      from_port   = var.caster_port
      to_port     = var.caster_port
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.cidr_block]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_admin_alb ? [1] : []
    content {
      description     = "Admin UI from admin ALB"
      from_port       = var.caster_port
      to_port         = var.caster_port
      protocol        = "tcp"
      security_groups = [aws_security_group.admin_alb[0].id]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_admin_alb && var.enable_prometheus ? [1] : []
    content {
      description     = "Prometheus from admin ALB"
      from_port       = var.prometheus_port
      to_port         = var.prometheus_port
      protocol        = "tcp"
      security_groups = [aws_security_group.admin_alb[0].id]
    }
  }

  # Direct workstation access when no admin ALB (VPN / jump). Skipped when ALB
  # owns the admin path so the SG story stays clear.
  dynamic "ingress" {
    for_each = !var.enable_admin_alb && length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Admin web UI (/admin on 2101) from workstation"
      from_port   = var.caster_port
      to_port     = var.caster_port
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  egress {
    description = "Allow outbound for package/BKG download and SSM"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ntripcaster" {
  name_prefix        = "${var.name_prefix}-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = "${var.name_prefix}-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ntripcaster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ntripcaster" {
  name_prefix = "${var.name_prefix}-"
  role        = aws_iam_role.ntripcaster.name

  tags = {
    Name = "${var.name_prefix}-profile"
  }
}

resource "aws_instance" "ntripcaster" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.ntripcaster.id]
  iam_instance_profile   = aws_iam_instance_profile.ntripcaster.name

  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    ntripcaster_version   = var.ntripcaster_version
    ntripcaster_sha256    = var.ntripcaster_sha256
    ntripcaster_url       = local.ntripcaster_url
    ntripcaster_tarball   = local.ntripcaster_tarball
    field_source_summary  = local.field_source_summary
    caster_server_name    = var.caster_server_name
    ntripcaster_prefix    = var.install_prefix
    conf_ntripcaster_b64  = base64encode(local.conf_ntripcaster)
    conf_users_b64        = base64encode(local.conf_users)
    conf_groups_b64       = base64encode(local.conf_groups)
    conf_clientmounts_b64 = base64encode(local.conf_clientmounts)
    conf_sourcemounts_b64 = base64encode(local.conf_sourcemounts)
    conf_sourcetable_b64  = base64encode(local.conf_sourcetable)
    enable_prometheus     = var.enable_admin_alb && var.enable_prometheus
    prometheus_image      = var.prometheus_image
    prometheus_port       = var.prometheus_port
    admin_username        = var.admin_username
    admin_password        = random_password.admin.result
    caster_port           = var.caster_port
  })

  # Config lives in templates/ — push via SSM + /admin?mode=rehash without rebuilding.
  # Taint/replace the instance when you need a fresh bootstrap (e.g. version bump).
  user_data_replace_on_change = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name               = var.name_prefix
    IngestPattern      = var.ingest_pattern
    FieldSourceNames   = local.field_source_names
    FieldSourceMounts  = join(",", local.field_source_mountpoints)
    NtripCasterVersion = var.ntripcaster_version
  }

  lifecycle {
    precondition {
      condition     = var.ntripcaster_sha256 != ""
      error_message = "Set ntripcaster_sha256 before apply."
    }

    precondition {
      condition     = var.ingest_pattern != "relay_iport" || length(var.field_sources) > 0
      error_message = "relay_iport requires at least one field_sources entry."
    }

    precondition {
      condition     = var.ingest_pattern != "source_push" || length(var.push_sources) > 0
      error_message = "source_push requires at least one push_sources entry."
    }

    precondition {
      condition     = var.ingest_pattern != "source_push" || (var.ntrip_push_username != "" && var.ntrip_push_password != "")
      error_message = "source_push requires ntrip_push_username and ntrip_push_password."
    }

    precondition {
      condition     = !var.enable_prometheus || var.enable_admin_alb
      error_message = "enable_prometheus requires enable_admin_alb (Prometheus is exposed on the admin ALB)."
    }
  }
}
