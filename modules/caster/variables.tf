variable "ingest_pattern" {
  type        = string
  description = "How streams arrive on the caster: relay_iport (pull raw TCP IPort) or source_push (device uploads to :2101)."

  validation {
    condition     = contains(["relay_iport", "source_push"], var.ingest_pattern)
    error_message = "ingest_pattern must be relay_iport or source_push."
  }
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID."

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must start with vpc-."
  }
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet for the caster EC2. For relay_iport, the subnet must have a route to the receiver IPort network."

  validation {
    condition     = startswith(var.private_subnet_id, "subnet-")
    error_message = "private_subnet_id must start with subnet-."
  }
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach TCP 2101 for the admin web UI."
  default     = []
}

variable "admin_username" {
  type        = string
  description = "Username for BKG /admin web UI."
  default     = "admin"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (m-series required)."
  default     = "m6a.large"

  validation {
    condition     = startswith(var.instance_type, "m")
    error_message = "instance_type must be an m-series type (e.g. m6a.large)."
  }
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GiB."
  default     = 30
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names and Name tags."
  default     = "ntripcaster"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all taggable resources."
  default     = {}
}

variable "ntripcaster_version" {
  type        = string
  description = "Pinned BKG Professional NtripCaster version."
  default     = "2.0.49"
}

variable "ntripcaster_sha256" {
  type        = string
  description = "SHA256 of the BKG ntripcaster tarball."
}

variable "caster_server_name" {
  type        = string
  description = "ntripcaster.conf server_name (must resolve to this host). Empty = private IP at bootstrap."
  default     = ""
}

variable "caster_display_name" {
  type        = string
  description = "Friendly caster name (name directive)."
  default     = "NtripCaster"
}

variable "caster_location" {
  type        = string
  description = "Admin UI location string."
  default     = "Unspecified"
}

variable "caster_operator" {
  type        = string
  description = "Operator name in ntripcaster.conf."
  default     = "Operator"
}

variable "caster_operator_url" {
  type        = string
  description = "Operator URL in ntripcaster.conf."
  default     = "http://localhost/"
}

variable "caster_rp_email" {
  type        = string
  description = "Responsible-party email on admin home."
  default     = "root@localhost"
}

variable "caster_url" {
  type        = string
  description = "Public/info URL for the caster."
  default     = "http://localhost/"
}

variable "caster_port" {
  type        = number
  description = "TCP listen port (port 80 never rendered)."
  default     = 2101
}

variable "install_prefix" {
  type        = string
  description = "Install prefix for ntripcaster."
  default     = "/usr/local/ntripcaster"
}

variable "cas_host_fallback" {
  type        = string
  description = "Placeholder CAS host when caster_server_name is empty."
  default     = "ntripcaster"
}

variable "admin_group" {
  type        = string
  description = "Group for /admin and /oper."
  default     = "admins"
}

variable "client_group" {
  type        = string
  description = "Group for NTRIP client mounts."
  default     = "clients"
}

variable "source_group" {
  type        = string
  description = "Group for NTRIP source push mounts (source_push pattern only)."
  default     = "sources"
}

variable "sourcetable_caster" {
  type = object({
    identifier = string
    operator   = string
    nmea       = number
    country    = string
    latitude   = string
    longitude  = string
    misc       = string
  })
  description = "Sourcetable CAS record fields."
  default = {
    identifier = "NtripCaster"
    operator   = "Operator"
    nmea       = 0
    country    = "NZL"
    latitude   = "-41.20"
    longitude  = "174.93"
    misc       = "NtripCaster"
  }
}

variable "sourcetable_network" {
  type = object({
    identifier     = string
    operator       = string
    authentication = string
    fee            = string
    web_net        = string
    web_str        = string
    web_reg        = string
    misc           = string
  })
  description = "Sourcetable NET record fields."
  default = {
    identifier     = "NtripNetwork"
    operator       = "Operator"
    authentication = "B"
    fee            = "N"
    web_net        = "none"
    web_str        = "none"
    web_reg        = "none"
    misc           = "none"
  }
}

variable "max_clients" {
  type    = number
  default = 1000
}

variable "max_clients_per_source" {
  type    = number
  default = 1000
}

variable "max_sources" {
  type    = number
  default = 40
}

variable "max_admins" {
  type    = number
  default = 2
}

variable "max_ip_connections" {
  type    = number
  default = 1000
}

variable "throttle" {
  type    = string
  default = "2000.0"
}

variable "logfile_debug_level" {
  type    = number
  default = 0
}

variable "acl_client_allow" {
  type    = list(string)
  default = ["*"]
}

variable "acl_admin_allow" {
  type    = list(string)
  default = ["127.0.0.1"]
}

variable "field_sources" {
  type = list(object({
    name       = string
    ip         = string
    port       = optional(number, 8857)
    mountpoint = string
    str        = string
  }))
  description = <<-EOT
    relay_iport only: receivers the caster dials (IPort). Each entry becomes a
    `relay pull` line, an STR, and a clientmount ACL.
  EOT
  default     = []

  validation {
    condition     = length(distinct([for s in var.field_sources : s.mountpoint])) == length(var.field_sources)
    error_message = "field_sources mountpoints must be unique."
  }

  validation {
    condition = alltrue([
      for s in var.field_sources : startswith(s.str, "STR;${s.mountpoint};")
    ])
    error_message = "Each field_sources str must start with 'STR;<mountpoint>;'."
  }
}

variable "push_sources" {
  type = list(object({
    name       = string
    mountpoint = string
    str        = string
  }))
  description = <<-EOT
    source_push only: mountpoints that field devices upload to on :2101.
    Each entry becomes an STR and sourcemounts/clientmounts ACL (no relay).
  EOT
  default     = []

  validation {
    condition     = length(distinct([for s in var.push_sources : s.mountpoint])) == length(var.push_sources)
    error_message = "push_sources mountpoints must be unique."
  }

  validation {
    condition = alltrue([
      for s in var.push_sources : startswith(s.str, "STR;${s.mountpoint};")
    ])
    error_message = "Each push_sources str must start with 'STR;<mountpoint>;'."
  }
}

variable "ntrip_client_username" {
  type        = string
  description = "Ntrip client username for pulling mounts (BNC / rovers)."
  default     = ""
}

variable "ntrip_client_password" {
  type        = string
  description = "Ntrip client password."
  default     = ""
  sensitive   = true
}

variable "ntrip_push_username" {
  type        = string
  description = "Ntrip v2 source username (source_push pattern). Ignored for relay_iport."
  default     = ""
}

variable "ntrip_push_password" {
  type        = string
  description = "Ntrip v2 source password (source_push pattern)."
  default     = ""
  sensitive   = true
}

# Backward-compatible aliases (examples can use either name).
variable "ntrip_source_username" {
  type        = string
  description = "Deprecated alias for ntrip_client_username."
  default     = ""
}

variable "ntrip_source_password" {
  type        = string
  description = "Deprecated alias for ntrip_client_password."
  default     = ""
  sensitive   = true
}

variable "enable_nlb" {
  type    = bool
  default = false
}

variable "allow_nlb_ingress" {
  type        = bool
  description = "Open caster SG for NLB client + VPC health-check traffic when enable_nlb=false (external NLB, e.g. HA example)."
  default     = false
}

variable "nlb_internal" {
  type    = bool
  default = true
}

variable "nlb_subnet_ids" {
  type    = list(string)
  default = []
}

variable "nlb_client_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "nlb_deregistration_delay" {
  type    = number
  default = 300
}

variable "nlb_stickiness" {
  type    = bool
  default = true
}

variable "nlb_deletion_protection" {
  type    = bool
  default = false
}

variable "enable_client" {
  type        = bool
  description = "Optional BNC Docker client EC2 that pulls mounts from the caster VIP/NLB."
  default     = false
}

variable "client_instance_type" {
  type        = string
  description = "Instance type for the BNC client EC2."
  default     = "t3.small"
}

variable "client_subnet_id" {
  type        = string
  description = "Subnet for the BNC client. Empty = private_subnet_id."
  default     = ""
}

variable "client_caster_host" {
  type        = string
  description = "Caster hostname/IP the BNC client dials. Empty = module NLB DNS or caster private IP."
  default     = ""
}

variable "bnc_image" {
  type        = string
  description = "Public GHCR image for BKG Ntrip Client (BNC)."
  default     = "ghcr.io/platformfuzz/bkg-ntrip-client-image:sha-7a31c2e"
}

variable "rinex_tools_image" {
  type        = string
  description = "Public GHCR image for RINEX QC helpers (rinex-tools check)."
  default     = "ghcr.io/platformfuzz/gnss-rinex-tools-image:latest"
}

variable "client_mount_format" {
  type        = string
  description = "BNC mountPoints format field (e.g. RTCM_3.3)."
  default     = "RTCM_3.3"
}

variable "enable_admin_alb" {
  type        = bool
  description = "Internal/public ALB for /admin (HTTP) restricted to admin_cidr_blocks. NTRIP stays on the NLB."
  default     = false
}

variable "admin_alb_internal" {
  type        = bool
  description = "Whether the admin ALB is internal. Use false + public subnets to reach it from a public admin_cidr."
  default     = true
}

variable "admin_alb_subnet_ids" {
  type        = list(string)
  description = "Subnets for the admin ALB (2+ AZs). Defaults to nlb_subnet_ids when empty."
  default     = []
}

variable "admin_alb_port" {
  type        = number
  description = "ALB listener port for the caster admin UI (forwards to caster_port)."
  default     = 80
}

variable "enable_prometheus" {
  type        = bool
  description = "Run Prometheus in Docker on the caster EC2 and expose it on the admin ALB."
  default     = false
}

variable "prometheus_port" {
  type        = number
  description = "Host/ALB port for the Prometheus UI and /metrics."
  default     = 9090
}

variable "prometheus_image" {
  type        = string
  description = "Prometheus container image."
  default     = "prom/prometheus:v2.55.1"
}
