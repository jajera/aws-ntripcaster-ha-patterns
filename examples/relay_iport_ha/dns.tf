# Stable VIP name → shared NLB (same region). Not Route53 failover routing.

resource "aws_route53_record" "ntrip_vip" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.ntrip.dns_name
    zone_id                = aws_lb.ntrip.zone_id
    evaluate_target_health = true
  }
}
