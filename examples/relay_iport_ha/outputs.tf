output "ntrip_vip_fqdn" {
  description = "Client VIP FQDN (Route53 alias → shared NLB). Dial this on :2101."
  value       = local.vip_fqdn
}

output "nlb_dns_name" {
  value = aws_lb.ntrip.dns_name
}

output "nlb_target_group_arn" {
  value = aws_lb_target_group.ntrip.arn
}

output "blue_instance_id" {
  value = module.blue.instance_id
}

output "green_instance_id" {
  value = module.green.instance_id
}

output "blue_private_ip" {
  value = module.blue.private_ip
}

output "green_private_ip" {
  value = module.green.private_ip
}

output "blue_admin_url" {
  description = "Admin on blue caster private IP (SSM port-forward preferred)."
  value       = module.blue.admin_url
}

output "blue_admin_password" {
  value     = module.blue.admin_password
  sensitive = true
}

output "green_admin_password" {
  value     = module.green.admin_password
  sensitive = true
}

output "field_source_mountpoints" {
  value = module.blue.field_source_mountpoints
}

output "caster_port" {
  value = local.caster_port
}

output "bnc_client_instance_id" {
  description = "Standalone BNC Docker client EC2 (null when enable_client is false)."
  value       = var.enable_client ? module.bnc_client[0].instance_id : null
}

output "bnc_client_private_ip" {
  value = var.enable_client ? module.bnc_client[0].private_ip : null
}
