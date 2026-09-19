# Single-region blue/green relay_iport HA: two warm casters behind one NLB.
#
#   cd examples/relay_iport_ha
#   cp terraform.tfvars.example terraform.tfvars
#   terraform init && terraform apply
#
# Clients dial ntrip_vip_fqdn:2101 (Route53 alias → shared NLB). Both blue and
# green are registered; NLB TCP health drops a dead node (~20s). Same region,
# two AZs — not multi-region DNS failover.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy     = "terraform"
      Service       = "ntripcaster"
      IngestPattern = "relay_iport"
      Example       = "relay_iport_ha"
    }
  }
}

locals {
  vip_fqdn = trimsuffix(
    "${var.route53_record_name}.${data.aws_route53_zone.this.name}",
    "."
  )

  caster_port = module.blue.caster_port

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

data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

module "blue" {
  source = "../../modules/caster"

  ingest_pattern = "relay_iport"

  vpc_id            = var.vpc_id
  private_subnet_id = var.blue_private_subnet_id
  name_prefix       = "ntrip-relay-ha-blue"

  admin_cidr_blocks = var.admin_cidr_blocks
  admin_username    = "admin"

  caster_server_name  = local.vip_fqdn
  caster_display_name = "Example NtripCaster HA Blue"
  caster_location     = local.caster_common.caster_location
  caster_operator     = local.caster_common.caster_operator
  caster_operator_url = local.caster_common.caster_operator_url
  caster_rp_email     = local.caster_common.caster_rp_email
  caster_url          = local.caster_common.caster_url

  sourcetable_caster  = local.caster_common.sourcetable_caster
  sourcetable_network = local.caster_common.sourcetable_network

  ntripcaster_version = "2.0.49"
  ntripcaster_sha256  = var.ntripcaster_sha256

  field_sources = var.field_sources

  ntrip_client_username = var.ntrip_client_username
  ntrip_client_password = var.ntrip_client_password

  # Shared NLB lives in nlb.tf (both instances attached).
  enable_nlb             = false
  allow_nlb_ingress      = true
  nlb_client_cidr_blocks = var.nlb_client_cidr_blocks

  enable_admin_alb  = false
  enable_prometheus = false
}

module "green" {
  source = "../../modules/caster"

  ingest_pattern = "relay_iport"

  vpc_id            = var.vpc_id
  private_subnet_id = var.green_private_subnet_id
  name_prefix       = "ntrip-relay-ha-green"

  admin_cidr_blocks = var.admin_cidr_blocks
  admin_username    = "admin"

  caster_server_name  = local.vip_fqdn
  caster_display_name = "Example NtripCaster HA Green"
  caster_location     = local.caster_common.caster_location
  caster_operator     = local.caster_common.caster_operator
  caster_operator_url = local.caster_common.caster_operator_url
  caster_rp_email     = local.caster_common.caster_rp_email
  caster_url          = local.caster_common.caster_url

  sourcetable_caster  = local.caster_common.sourcetable_caster
  sourcetable_network = local.caster_common.sourcetable_network

  ntripcaster_version = "2.0.49"
  ntripcaster_sha256  = var.ntripcaster_sha256

  field_sources = var.field_sources

  ntrip_client_username = var.ntrip_client_username
  ntrip_client_password = var.ntrip_client_password

  enable_nlb             = false
  allow_nlb_ingress      = true
  nlb_client_cidr_blocks = var.nlb_client_cidr_blocks

  enable_admin_alb  = false
  enable_prometheus = false
}
