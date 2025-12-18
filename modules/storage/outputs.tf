output "assets_bucket_id" {
  description = "Assets S3 bucket ID"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_name" {
  description = "Assets S3 bucket name"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "Assets S3 bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "assets_bucket_domain_name" {
  description = "Assets bucket domain name"
  value       = aws_s3_bucket.assets.bucket_domain_name
}

output "assets_bucket_regional_domain" {
  description = "Assets bucket regional domain name"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "data_bucket_id" {
  description = "Data S3 bucket ID"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_name" {
  description = "Data S3 bucket name"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "Data S3 bucket ARN"
  value       = aws_s3_bucket.data.arn
}

output "logs_bucket_id" {
  description = "Logs S3 bucket ID"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "cloudfront_oai_arn" {
  description = "CloudFront Origin Access Identity ARN"
  value       = aws_cloudfront_origin_access_identity.assets.iam_arn
}

output "cloudfront_oai_path" {
  description = "CloudFront Origin Access Identity path"
  value       = aws_cloudfront_origin_access_identity.assets.cloudfront_access_identity_path
}
