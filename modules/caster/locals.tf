locals {
  # Module-owned NLB, or external NLB (HA example) when allow_nlb_ingress is set.
  nlb_ingress_enabled = var.enable_nlb || var.allow_nlb_ingress

  common_tags = merge(
    {
      Name          = var.name_prefix
      ManagedBy     = "terraform"
      Service       = "ntripcaster"
      IngestPattern = var.ingest_pattern
    },
    var.tags,
  )

  ntripcaster_tarball = "ntripcaster-${var.ntripcaster_version}.tar.bz2"
  ntripcaster_url     = "https://igs.bkg.bund.de/root_ftp/NTRIP/software/caster/${local.ntripcaster_tarball}"

  # Prefer new names; fall back to deprecated aliases.
  client_username = coalesce(
    var.ntrip_client_username != "" ? var.ntrip_client_username : null,
    var.ntrip_source_username != "" ? var.ntrip_source_username : null,
    ""
  )
  client_password = coalesce(
    var.ntrip_client_password != "" ? var.ntrip_client_password : null,
    var.ntrip_source_password != "" ? var.ntrip_source_password : null,
    ""
  )

  # Unified mount inventory for sourcetable + clientmounts.
  mounts = var.ingest_pattern == "relay_iport" ? [
    for s in var.field_sources : {
      name       = s.name
      mountpoint = s.mountpoint
      str        = s.str
    }
    ] : [
    for s in var.push_sources : {
      name       = s.name
      mountpoint = s.mountpoint
      str        = s.str
    }
  ]

  # Relays only for IPort pull pattern.
  relay_sources = var.ingest_pattern == "relay_iport" ? var.field_sources : []

  field_source_summary = var.ingest_pattern == "relay_iport" ? join(", ", [
    for s in var.field_sources : "${s.name} ${s.ip}:${s.port} -> /${s.mountpoint}"
    ]) : join(", ", [
    for s in var.push_sources : "${s.name} push -> /${s.mountpoint}"
  ])

  field_source_names       = join(",", [for m in local.mounts : m.name])
  field_source_mountpoints = [for m in local.mounts : m.mountpoint]

  cas_host = var.caster_server_name != "" ? var.caster_server_name : var.cas_host_fallback

  # When admin ALB is enabled, TCP source at the caster is the ALB nodes.
  # BKG ACL CIDR matching is unreliable for this path; allow admin * and rely
  # on the ALB security group (admin_cidr_blocks) as the real gate.
  acl_admin_allow = var.enable_admin_alb ? distinct(concat(var.acl_admin_allow, ["*"])) : var.acl_admin_allow

  conf_ntripcaster = templatefile("${path.module}/templates/ntripcaster.conf.tftpl", {
    prefix                 = var.install_prefix
    caster_port            = var.caster_port
    caster_server_name     = local.cas_host
    caster_display_name    = var.caster_display_name
    caster_location        = var.caster_location
    caster_operator        = var.caster_operator
    caster_operator_url    = var.caster_operator_url
    caster_rp_email        = var.caster_rp_email
    caster_url             = var.caster_url
    max_clients            = var.max_clients
    max_clients_per_source = var.max_clients_per_source
    max_sources            = var.max_sources
    max_admins             = var.max_admins
    max_ip_connections     = var.max_ip_connections
    throttle               = var.throttle
    logfile_debug_level    = var.logfile_debug_level
    acl_client_allow       = var.acl_client_allow
    acl_admin_allow        = local.acl_admin_allow
    relay_sources          = local.relay_sources
    ingest_pattern         = var.ingest_pattern
    admin_password         = random_password.admin.result
    oper_password          = random_password.oper.result
    encoder_password       = random_password.encoder.result
  })

  conf_sourcetable = templatefile("${path.module}/templates/sourcetable.dat.tftpl", {
    mounts      = local.mounts
    cas_host    = local.cas_host
    caster_port = var.caster_port
    caster      = var.sourcetable_caster
    network     = var.sourcetable_network
  })

  conf_users = templatefile("${path.module}/templates/users.aut.tftpl", {
    admin_username        = var.admin_username
    admin_password        = random_password.admin.result
    ntrip_client_username = local.client_username
    ntrip_client_password = local.client_password
    ntrip_push_username   = var.ntrip_push_username
    ntrip_push_password   = var.ntrip_push_password
  })

  conf_groups = templatefile("${path.module}/templates/groups.aut.tftpl", {
    admin_username        = var.admin_username
    admin_group           = var.admin_group
    client_group          = var.client_group
    source_group          = var.source_group
    ntrip_client_username = local.client_username
    ntrip_push_username   = var.ntrip_push_username
  })

  conf_clientmounts = templatefile("${path.module}/templates/clientmounts.aut.tftpl", {
    mounts                = local.mounts
    admin_group           = var.admin_group
    client_group          = var.client_group
    ntrip_client_username = local.client_username
  })

  conf_sourcemounts = templatefile("${path.module}/templates/sourcemounts.aut.tftpl", {
    ingest_pattern      = var.ingest_pattern
    mounts              = local.mounts
    source_group        = var.source_group
    ntrip_push_username = var.ntrip_push_username
  })
}
