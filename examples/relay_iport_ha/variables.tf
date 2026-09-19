variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_id" {
  type = string
}

variable "blue_private_subnet_id" {
  type        = string
  description = "Private subnet for the blue caster (different AZ from green)."
}

variable "green_private_subnet_id" {
  type        = string
  description = "Private subnet for the green caster (different AZ from blue)."
}

variable "nlb_subnet_ids" {
  type        = list(string)
  description = "Private subnets for the shared NLB (2+ AZs)."
}

variable "nlb_client_cidr_blocks" {
  type        = list(string)
  description = "CIDRs of NTRIP clients (instance-target NLB preserves source IP)."
  default     = ["10.0.0.0/8"]
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "Optional direct admin access to caster :2101 (SSM preferred)."
  default     = []
}

variable "route53_zone_id" {
  type        = string
  description = "Private hosted zone ID associated with the VPC."
}

variable "route53_record_name" {
  type        = string
  description = "Relative record name for the VIP (e.g. ntrip). FQDN = name.zone."
  default     = "ntrip"
}

variable "nlb_deletion_protection" {
  type    = bool
  default = false
}

variable "nlb_deregistration_delay" {
  type    = number
  default = 300
}

variable "nlb_stickiness" {
  type    = bool
  default = true
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

variable "enable_client" {
  type        = bool
  description = "Run a standalone BNC Docker client EC2 that pulls the VIP."
  default     = true
}

variable "bnc_client_subnet_id" {
  type        = string
  description = "Subnet for the BNC client. Empty = blue_private_subnet_id."
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
  description = "Receivers both casters relay-pull. Override in terraform.tfvars."
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
