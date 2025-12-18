output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID (for Route 53)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "static_cache_policy_id" {
  description = "Cache policy ID for static assets"
  value       = aws_cloudfront_cache_policy.static.id
}

output "dynamic_cache_policy_id" {
  description = "Cache policy ID for dynamic content"
  value       = aws_cloudfront_cache_policy.dynamic.id
}

output "origin_request_policy_id" {
  description = "Origin request policy ID for Lambda"
  value       = aws_cloudfront_origin_request_policy.lambda.id
}

output "security_headers_function_arn" {
  description = "CloudFront function ARN for security headers"
  value       = aws_cloudfront_function.security_headers.arn
}

output "frontend_url" {
  description = "Frontend URL (custom domain or CloudFront)"
  value       = var.enable_custom_domain && var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${aws_cloudfront_distribution.main.domain_name}"
}
