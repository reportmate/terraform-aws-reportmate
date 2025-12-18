output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "api_cache_policy_id" {
  description = "API cache policy ID"
  value       = aws_cloudfront_cache_policy.api.id
}

output "api_origin_request_policy_id" {
  description = "API origin request policy ID"
  value       = aws_cloudfront_origin_request_policy.api.id
}
