output "ntrip_vip_fqdn" {
  description = "Client VIP FQDN (Route53 failover PRIMARY→AKL NLB, SECONDARY→SYD NLB)."
  value       = local.vip_fqdn
}

output "primary_region" {
  value = var.primary_region
}

output "secondary_region" {
  value = var.secondary_region
}

output "primary_aws_profile" {
  value = var.primary_aws_profile
}

output "secondary_aws_profile" {
  value = var.secondary_aws_profile
}

output "primary_instance_id" {
  value = module.primary.instance_id
}

output "secondary_instance_id" {
  value = module.secondary.instance_id
}

output "primary_private_ip" {
  value = module.primary.private_ip
}

output "secondary_private_ip" {
  value = module.secondary.private_ip
}

output "primary_nlb_dns_name" {
  value = module.primary.nlb_dns_name
}

output "secondary_nlb_dns_name" {
  value = module.secondary.nlb_dns_name
}

output "primary_nlb_target_group_arn" {
  value = module.primary.nlb_target_group_arn
}

output "secondary_nlb_target_group_arn" {
  value = module.secondary.nlb_target_group_arn
}

output "primary_admin_password" {
  value     = module.primary.admin_password
  sensitive = true
}

output "secondary_admin_password" {
  value     = module.secondary.admin_password
  sensitive = true
}

output "field_source_mountpoints" {
  value = module.primary.field_source_mountpoints
}

output "caster_port" {
  value = local.caster_port
}

output "bnc_client_instance_id" {
  description = "BNC client in primary region (null when enable_client is false)."
  value       = var.enable_client ? module.bnc_client[0].instance_id : null
}

output "bnc_client_private_ip" {
  value = var.enable_client ? module.bnc_client[0].private_ip : null
}
