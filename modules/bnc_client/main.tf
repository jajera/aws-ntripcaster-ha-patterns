# Standalone BKG Ntrip Client (BNC) EC2 — Docker image from GHCR.
# Used by examples/relay_iport_ha and optionally by modules/caster (enable_client).

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
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

resource "aws_iam_role" "this" {
  name_prefix        = "${var.name_prefix}-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = "${var.name_prefix}-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name_prefix}-"
  role        = aws_iam_role.this.name

  tags = {
    Name = "${var.name_prefix}-profile"
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-"
  description = "BNC Docker client - outbound only"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (caster VIP/NLB + GHCR + SSM)"
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

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    bnc_image         = var.bnc_image
    rinex_tools_image = var.rinex_tools_image
    caster_host       = var.caster_host
    caster_port       = var.caster_port
    mount             = var.mountpoint
    client_user       = var.ntrip_username
    client_pass       = var.ntrip_password
    mount_format      = var.mount_format
    country           = var.country
    latitude          = var.latitude
    longitude         = var.longitude
  })

  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = var.name_prefix
  })

  lifecycle {
    ignore_changes = [ami]
  }
}
