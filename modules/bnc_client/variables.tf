variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Private subnet with VPC DNS (for VIP) and egress to GHCR."
}

variable "name_prefix" {
  type    = string
  default = "ntrip-bnc-client"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "bnc_image" {
  type        = string
  description = "Public GHCR image for BKG Ntrip Client."
  default     = "ghcr.io/platformfuzz/bkg-ntrip-client-image:sha-7a31c2e"
}

variable "rinex_tools_image" {
  type        = string
  description = "Public GHCR image for RINEX QC helpers (rinex-tools check)."
  default     = "ghcr.io/platformfuzz/gnss-rinex-tools-image:latest"
}

variable "caster_host" {
  type        = string
  description = "Caster hostname or IP (e.g. ntrip.geonet.cloud or NLB DNS)."
}

variable "caster_port" {
  type    = number
  default = 2101
}

variable "mountpoint" {
  type = string
}

variable "ntrip_username" {
  type = string
}

variable "ntrip_password" {
  type      = string
  sensitive = true
}

variable "mount_format" {
  type    = string
  default = "RTCM_3"
}

variable "country" {
  type    = string
  default = "NZL"
}

variable "latitude" {
  type    = string
  default = "-41.20"
}

variable "longitude" {
  type    = string
  default = "174.93"
}

variable "tags" {
  type    = map(string)
  default = {}
}
