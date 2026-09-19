variable "primary_region" {
  type        = string
  description = "PRIMARY region (Route53 failover)."
  default     = "ap-southeast-6"
}

variable "secondary_region" {
  type        = string
  description = "SECONDARY region (Route53 failover)."
  default     = "ap-southeast-2"
}

variable "primary_aws_profile" {
  type        = string
  description = "AWS shared-config profile for the PRIMARY (Auckland) account."
}

variable "secondary_aws_profile" {
  type        = string
  description = "AWS shared-config profile for the SECONDARY (Sydney) account (also owns the private hosted zone)."
}

# --- primary (Auckland) ---

variable "primary_vpc_id" {
  type = string
}

variable "primary_private_subnet_id" {
  type        = string
  description = "Private subnet for the primary caster (must reach receiver IPort)."
}

variable "primary_nlb_subnet_ids" {
  type        = list(string)
  description = "NLB subnets in primary (2+ AZs even with a single target)."
}

variable "primary_nlb_client_cidr_blocks" {
  type        = list(string)
  description = "CIDRs of NTRIP clients reaching the primary NLB."
  default     = ["10.0.0.0/8"]
}

# --- secondary (Sydney) ---

variable "secondary_vpc_id" {
  type = string
}

variable "secondary_private_subnet_id" {
  type        = string
  description = "Private subnet for the secondary caster (must reach receiver IPort)."
}

variable "secondary_nlb_subnet_ids" {
  type        = list(string)
  description = "NLB subnets in secondary (2+ AZs)."
}

variable "secondary_nlb_client_cidr_blocks" {
  type        = list(string)
  description = "CIDRs of NTRIP clients reaching the secondary NLB."
  default     = ["10.0.0.0/8"]
}

# --- shared ---

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "Optional direct admin access to caster :2101 (SSM preferred)."
  default     = []
}

variable "route53_zone_id" {
  type        = string
  description = "Private hosted zone ID associated with BOTH regional VPCs."
}

variable "route53_record_name" {
  type        = string
  description = "Relative VIP name (e.g. ntrip). FQDN = name.zone."
  default     = "ntrip"
}

variable "ntripcaster_sha256" {
  type    = string
  default = "731e7403c7eeb9348e6d18474e02981d08ec702ade2bf56bc93fa81954dcfa9b"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for both regional casters. ap-southeast-6 has no m6a; use m6i.large."
  default     = "m6i.large"
}

variable "ntrip_client_username" {
  type    = string
  default = "client"
}

variable "ntrip_client_password" {
  type      = string
  sensitive = true
}

variable "enable_client" {
  type        = bool
  description = "Run a standalone BNC Docker client EC2 in the primary region that pulls the VIP."
  default     = true
}

variable "bnc_client_subnet_id" {
  type        = string
  description = "Subnet for BNC in primary. Empty = primary_private_subnet_id."
  default     = ""
}

variable "bnc_image" {
  type        = string
  description = "Public GHCR BNC image."
  default     = "ghcr.io/platformfuzz/bkg-ntrip-client-image:sha-7a31c2e"
}

variable "rinex_tools_image" {
  type        = string
  description = "Public GHCR RINEX QC image (rinex-tools check)."
  default     = "ghcr.io/platformfuzz/gnss-rinex-tools-image:latest"
}

variable "field_sources" {
  type = list(object({
    name       = string
    ip         = string
    port       = number
    mountpoint = string
    str        = string
  }))
  description = "Receivers both regional casters relay-pull. Override in terraform.tfvars."
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
