output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "zone_name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : []
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
}

output "main_record_name" {
  description = "Main A record name"
  value       = length(aws_route53_record.main) > 0 ? aws_route53_record.main[0].name : null
}

output "api_record_name" {
  description = "API A record name"
  value       = length(aws_route53_record.api) > 0 ? aws_route53_record.api[0].name : null
}

output "health_check_id" {
  description = "Route 53 health check ID"
  value       = length(aws_route53_health_check.main) > 0 ? aws_route53_health_check.main[0].id : null
}
