# BNC client in the primary region; pulls the multi-region VIP.

module "bnc_client" {
  count  = var.enable_client ? 1 : 0
  source = "../../modules/bnc_client"
  providers = {
    aws = aws.primary
  }

  vpc_id      = var.primary_vpc_id
  subnet_id   = var.bnc_client_subnet_id != "" ? var.bnc_client_subnet_id : var.primary_private_subnet_id
  name_prefix = "ntrip-relay-mr-bnc"

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
