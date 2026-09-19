# Example: caster-side relay pull of a raw TCP IPort stream.
#
#   cd examples/relay_iport
#   cp terraform.tfvars.example terraform.tfvars   # fill VPC / subnet / receiver
#   terraform init && terraform apply
#
# Reuses ../../modules/caster — do not edit templates here.

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
      Example       = "relay_iport"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type        = string
  description = "Subnet that can reach the receiver IPort address."
}

variable "admin_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "enable_nlb" {
  type    = bool
  default = true
}

variable "nlb_subnet_ids" {
  type    = list(string)
  default = []
}

variable "nlb_client_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "enable_admin_alb" {
  type    = bool
  default = false
}

variable "admin_alb_internal" {
  type    = bool
  default = true
}

variable "admin_alb_subnet_ids" {
  type        = list(string)
  description = "ALB subnets; defaults to nlb_subnet_ids. Use public subnets when admin_alb_internal=false."
  default     = []
}

variable "enable_prometheus" {
  type    = bool
  default = false
}

variable "caster_server_name" {
  type    = string
  default = ""
}

variable "ntripcaster_sha256" {
  type    = string
  default = "731e7403c7eeb9348e6d18474e02981d08ec702ade2bf56bc93fa81954dcfa9b"
}

variable "ntrip_client_username" {
  type    = string
  default = "client"
}

variable "ntrip_client_password" {
  type      = string
  sensitive = true
}

variable "field_sources" {
  type = list(object({
    name       = string
    ip         = string
    port       = number
    mountpoint = string
    str        = string
  }))
  description = "Receivers to relay-pull. Override in terraform.tfvars."
  default = [
    {
      name       = "example-receiver"
      ip         = "10.0.10.10"
      port       = 8857
      mountpoint = "EXMP00XXX0"
      str        = "STR;EXMP00XXX0;Example Site;RTCM 3.2;1004(1),1012(1);2;GPS+GLO;ExampleOrg;XXX;0.00;0.00;0;0;Generic Receiver;none;B;N;9600;"
    },
  ]
}

module "caster" {
  source = "../../modules/caster"

  ingest_pattern = "relay_iport"

  vpc_id            = var.vpc_id
  private_subnet_id = var.private_subnet_id
  name_prefix       = "ntrip-relay-iport"

  admin_cidr_blocks = var.admin_cidr_blocks
  admin_username    = "admin"

  caster_server_name  = var.caster_server_name
  caster_display_name = "Example NtripCaster"
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

  ntripcaster_version = "2.0.49"
  ntripcaster_sha256  = var.ntripcaster_sha256

  field_sources = var.field_sources

  ntrip_client_username = var.ntrip_client_username
  ntrip_client_password = var.ntrip_client_password

  enable_nlb             = var.enable_nlb
  nlb_subnet_ids         = var.nlb_subnet_ids
  nlb_client_cidr_blocks = var.nlb_client_cidr_blocks

  enable_admin_alb     = var.enable_admin_alb
  admin_alb_internal   = var.admin_alb_internal
  admin_alb_subnet_ids = var.admin_alb_subnet_ids
  enable_prometheus    = var.enable_prometheus
}

output "ingest_pattern" { value = module.caster.ingest_pattern }
output "instance_id" { value = module.caster.instance_id }
output "private_ip" { value = module.caster.private_ip }
output "admin_url" { value = module.caster.admin_url }
output "admin_alb_dns_name" { value = module.caster.admin_alb_dns_name }
output "prometheus_url" { value = module.caster.prometheus_url }
output "admin_password" {
  value     = module.caster.admin_password
  sensitive = true
}
output "nlb_dns_name" { value = module.caster.nlb_dns_name }
output "nlb_target_group_arn" { value = module.caster.nlb_target_group_arn }
output "field_source_mountpoints" { value = module.caster.field_source_mountpoints }
