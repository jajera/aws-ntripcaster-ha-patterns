output "ingest_pattern" {
  description = "Deployed ingest pattern (relay_iport or source_push)."
  value       = var.ingest_pattern
}

output "caster_port" {
  description = "TCP port clients and NLB health checks use."
  value       = var.caster_port
}

output "instance_id" {
  description = "EC2 instance ID running ntripcaster."
  value       = aws_instance.ntripcaster.id
}

output "private_ip" {
  description = "Private IP of the ntripcaster instance."
  value       = aws_instance.ntripcaster.private_ip
}

output "security_group_id" {
  description = "Security group ID allowing NTRIP source ingress on 2101."
  value       = aws_security_group.ntripcaster.id
}

output "ntripcaster_version" {
  description = "Pinned BKG NtripCaster version installed by user_data."
  value       = var.ntripcaster_version
}

output "field_source_mountpoints" {
  description = "Configured field source mountpoints (inventory)."
  value       = local.field_source_mountpoints
}

output "admin_cidr_blocks" {
  description = "CIDRs allowed for admin web access on TCP 2101."
  value       = var.admin_cidr_blocks
}

output "admin_username" {
  description = "HTTP basic username for http://<private_ip>:2101/admin"
  value       = var.admin_username
}

output "admin_password" {
  description = "HTTP basic password for /admin (also admin_password in ntripcaster.conf)."
  value       = random_password.admin.result
  sensitive   = true
}

output "admin_url" {
  description = "Admin web URL (ALB when enable_admin_alb, else private IP)."
  value = var.enable_admin_alb ? (
    "http://${aws_lb.admin[0].dns_name}:${var.admin_alb_port}/admin"
    ) : (
    "http://${aws_instance.ntripcaster.private_ip}:${var.caster_port}/admin"
  )
}

output "admin_alb_dns_name" {
  description = "Admin ALB DNS name (null when disabled)."
  value       = var.enable_admin_alb ? aws_lb.admin[0].dns_name : null
}

output "prometheus_url" {
  description = "Prometheus UI (opens graph on caster_connected_sources). Null when disabled."
  value = var.enable_admin_alb && var.enable_prometheus ? (
    "http://${aws_lb.admin[0].dns_name}:${var.prometheus_port}/graph?g0.expr=caster_connected_sources&g0.tab=0&g0.range_input=15m"
  ) : null
}

output "client_instance_id" {
  description = "BNC client EC2 instance ID (null when enable_client is false). SSM in to check /opt/bnc/logs."
  value       = var.enable_client ? module.bnc_client[0].instance_id : null
}

output "client_private_ip" {
  description = "BNC client private IP (null when disabled)."
  value       = var.enable_client ? module.bnc_client[0].private_ip : null
}

output "nlb_dns_name" {
  description = "NLB DNS name. Point NTRIP clients here, and set caster_server_name to this value so the sourcetable CAS host matches."
  value       = var.enable_nlb ? aws_lb.ntripcaster[0].dns_name : null
}

output "nlb_zone_id" {
  description = "NLB Route53 hosted zone ID (for alias records)."
  value       = var.enable_nlb ? aws_lb.ntripcaster[0].zone_id : null
}

output "nlb_arn" {
  description = "NLB ARN."
  value       = var.enable_nlb ? aws_lb.ntripcaster[0].arn : null
}

output "nlb_target_group_arn" {
  description = "Target group ARN. Check target health with: aws elbv2 describe-target-health --target-group-arn <arn>"
  value       = var.enable_nlb ? aws_lb_target_group.ntripcaster[0].arn : null
}
