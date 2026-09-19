# Standalone BNC client (not part of blue/green casters). Pulls the HA VIP.

module "bnc_client" {
  count  = var.enable_client ? 1 : 0
  source = "../../modules/bnc_client"

  vpc_id      = var.vpc_id
  subnet_id   = var.bnc_client_subnet_id != "" ? var.bnc_client_subnet_id : var.blue_private_subnet_id
  name_prefix = "ntrip-relay-ha-bnc"

  bnc_image         = var.bnc_image
  rinex_tools_image = var.rinex_tools_image

  caster_host = local.vip_fqdn
  caster_port = local.caster_port
  mountpoint  = var.field_sources[0].mountpoint

  ntrip_username = var.ntrip_client_username
  ntrip_password = var.ntrip_client_password

  mount_format = "RTCM_3"
  country      = "NZL"
  latitude     = "-41.20"
  longitude    = "174.93"
}
