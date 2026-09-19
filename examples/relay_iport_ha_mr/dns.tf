# Same VIP FQDN → PRIMARY (Auckland NLB) / SECONDARY (Sydney NLB).
# Zone + records live in the SECONDARY account (provider aws.secondary).
# Alias targets may be cross-account (PRIMARY NLB in the Auckland account).

resource "aws_route53_record" "ntrip_vip_primary" {
  provider = aws.secondary

  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.route53_record_name
  type    = "A"

  set_identifier = "primary-${var.primary_region}"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = module.primary.nlb_dns_name
    zone_id                = module.primary.nlb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ntrip_vip_secondary" {
  provider = aws.secondary

  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.route53_record_name
  type    = "A"

  set_identifier = "secondary-${var.secondary_region}"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = module.secondary.nlb_dns_name
    zone_id                = module.secondary.nlb_zone_id
    evaluate_target_health = true
  }
}
