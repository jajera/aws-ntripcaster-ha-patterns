# Optional BNC client — wraps modules/bnc_client when enable_client = true.
# Prefer calling modules/bnc_client directly from HA examples (own name/IAM).

module "bnc_client" {
  count  = var.enable_client ? 1 : 0
  source = "../bnc_client"

  vpc_id      = var.vpc_id
  subnet_id   = coalesce(var.client_subnet_id != "" ? var.client_subnet_id : null, var.private_subnet_id)
  name_prefix = "${var.name_prefix}-bnc-client"

  instance_type     = var.client_instance_type
  bnc_image         = var.bnc_image
  rinex_tools_image = var.rinex_tools_image

  caster_host = (
    var.client_caster_host != "" ? var.client_caster_host : (
      length(aws_lb.ntripcaster) > 0 ? aws_lb.ntripcaster[0].dns_name : aws_instance.ntripcaster.private_ip
    )
  )
  caster_port = var.caster_port
  mountpoint  = length(local.field_source_mountpoints) > 0 ? local.field_source_mountpoints[0] : "unset"

  ntrip_username = local.client_username
  ntrip_password = local.client_password
  mount_format   = var.client_mount_format
  country        = var.sourcetable_caster.country
  latitude       = var.sourcetable_caster.latitude
  longitude      = var.sourcetable_caster.longitude

  tags = var.tags
}

check "enable_client_requires_creds_and_mount" {
  assert {
    condition     = !var.enable_client || (local.client_username != "" && local.client_password != "")
    error_message = "enable_client requires ntrip_client_username and ntrip_client_password."
  }
  assert {
    condition     = !var.enable_client || length(local.field_source_mountpoints) > 0
    error_message = "enable_client requires at least one mount (field_sources or push_sources)."
  }
}
