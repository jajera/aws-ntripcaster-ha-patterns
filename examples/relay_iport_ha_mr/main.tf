# Multi-region relay_iport HA: one caster + NLB per region.
#
#   PRIMARY   ap-southeast-6 (Auckland)
#   SECONDARY ap-southeast-2 (Sydney)
#
# Clients dial ntrip_vip_fqdn:2101. Route53 failover aliases point at each
# regional NLB (evaluate_target_health). No per-region blue/green.
#
#   cd examples/relay_iport_ha_mr
#   cp terraform.tfvars.example terraform.tfvars
#   terraform init && terraform apply

locals {
  vip_fqdn = trimsuffix(
    "${var.route53_record_name}.${data.aws_route53_zone.this.name}",
    "."
  )

  caster_port = module.primary.caster_port

  caster_common = {
    caster_location     = "Example City"
    caster_operator     = "ExampleOrg"
    caster_operator_url = "https://example.org/"
    caster_rp_email     = "ops@example.org"
    caster_url          = "https://example.org/"
    sourcetable_caster = {
      identifier = "ExampleOrg"
      operator   = "ExampleOrg"
      nmea       = 0
      country    = "XXX"
      latitude   = "0.00"
      longitude  = "0.00"
      misc       = "NtripCaster"
    }
    sourcetable_network = {
      identifier     = "ExampleOrg"
      operator       = "ExampleOrg"
      authentication = "B"
      fee            = "N"
      web_net        = "https://example.org/"
      web_str        = "none"
      web_reg        = "none"
      misc           = "none"
    }
  }
}

# Private hosted zone lives in the SECONDARY (Sydney) account.
data "aws_route53_zone" "this" {
  provider = aws.secondary
  zone_id  = var.route53_zone_id
}

module "primary" {
  source = "../../modules/caster"
  providers = {
    aws = aws.primary
  }

  ingest_pattern = "relay_iport"

  vpc_id            = var.primary_vpc_id
  private_subnet_id = var.primary_private_subnet_id
  name_prefix       = "ntrip-relay-mr-akl"

  admin_cidr_blocks = var.admin_cidr_blocks
  admin_username    = "admin"

  caster_server_name  = local.vip_fqdn
  caster_display_name = "Example NtripCaster MR Primary (AKL)"
  caster_location     = local.caster_common.caster_location
  caster_operator     = local.caster_common.caster_operator
  caster_operator_url = local.caster_common.caster_operator_url
  caster_rp_email     = local.caster_common.caster_rp_email
  caster_url          = local.caster_common.caster_url

  sourcetable_caster  = local.caster_common.sourcetable_caster
  sourcetable_network = local.caster_common.sourcetable_network

  ntripcaster_version = "2.0.49"
  ntripcaster_sha256  = var.ntripcaster_sha256
  instance_type       = var.instance_type

  field_sources = var.field_sources

  ntrip_client_username = var.ntrip_client_username
  ntrip_client_password = var.ntrip_client_password

  enable_nlb             = true
  nlb_internal           = true
  nlb_subnet_ids         = var.primary_nlb_subnet_ids
  nlb_client_cidr_blocks = var.primary_nlb_client_cidr_blocks

  enable_admin_alb  = false
  enable_prometheus = false
}

module "secondary" {
  source = "../../modules/caster"
  providers = {
    aws = aws.secondary
  }

  ingest_pattern = "relay_iport"

  vpc_id            = var.secondary_vpc_id
  private_subnet_id = var.secondary_private_subnet_id
  name_prefix       = "ntrip-relay-mr-syd"

  admin_cidr_blocks = var.admin_cidr_blocks
  admin_username    = "admin"

  caster_server_name  = local.vip_fqdn
  caster_display_name = "Example NtripCaster MR Secondary (SYD)"
  caster_location     = local.caster_common.caster_location
  caster_operator     = local.caster_common.caster_operator
  caster_operator_url = local.caster_common.caster_operator_url
  caster_rp_email     = local.caster_common.caster_rp_email
  caster_url          = local.caster_common.caster_url

  sourcetable_caster  = local.caster_common.sourcetable_caster
  sourcetable_network = local.caster_common.sourcetable_network

  ntripcaster_version = "2.0.49"
  ntripcaster_sha256  = var.ntripcaster_sha256
  instance_type       = var.instance_type

  field_sources = var.field_sources

  ntrip_client_username = var.ntrip_client_username
  ntrip_client_password = var.ntrip_client_password

  enable_nlb             = true
  nlb_internal           = true
  nlb_subnet_ids         = var.secondary_nlb_subnet_ids
  nlb_client_cidr_blocks = var.secondary_nlb_client_cidr_blocks

  enable_admin_alb  = false
  enable_prometheus = false
}
