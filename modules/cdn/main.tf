# CDN Module - CloudFront with Lambda Function URL Origins (Serverless)
# Replaces Azure Front Door

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  # Extract domain from Lambda Function URL
  lambda_domain = var.lambda_function_url != "" ? replace(replace(var.lambda_function_url, "https://", ""), "/", "") : ""

  # Extract domain from image optimizer URL
  image_optimizer_domain = var.image_optimizer_url != "" ? replace(replace(var.image_optimizer_url, "https://", ""), "/", "") : ""

  # Extract API Gateway domain
  api_domain = var.api_endpoint != "" ? replace(replace(split("/", var.api_endpoint)[2], "https://", ""), "/", "") : ""
}

# Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.project_name}-${var.environment}-assets-oac"
  description                       = "OAC for S3 assets bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 Bucket Policy for CloudFront OAC
resource "aws_s3_bucket_policy" "assets" {
  bucket = var.assets_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.assets_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# Cache Policies
resource "aws_cloudfront_cache_policy" "static" {
  name        = "${var.project_name}-${var.environment}-static-cache"
  comment     = "Cache policy for static assets"
  default_ttl = 604800   # 7 days
  max_ttl     = 31536000 # 1 year
  min_ttl     = 86400    # 1 day

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_cache_policy" "dynamic" {
  name        = "${var.project_name}-${var.environment}-dynamic-cache"
  comment     = "Cache policy for dynamic SSR content"
  default_ttl = 0
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Host", "Accept", "Accept-Language"]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# Origin Request Policy for Lambda
resource "aws_cloudfront_origin_request_policy" "lambda" {
  name    = "${var.project_name}-${var.environment}-lambda-origin"
  comment = "Origin request policy for Lambda Function URL"

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Accept", "Accept-Language", "Authorization", "CloudFront-Viewer-Country"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} serverless distribution"
  default_root_object = ""
  price_class         = var.price_class
  aliases             = var.enable_custom_domain && var.custom_domain_name != "" ? [var.custom_domain_name] : []

  # Origin - Lambda Function URL (Next.js SSR)
  origin {
    domain_name = local.lambda_domain
    origin_id   = "Lambda-nextjs"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-origin-verify"
      value = "${var.project_name}-${var.environment}"
    }
  }

  # Origin - S3 Assets
  origin {
    domain_name              = var.assets_bucket_regional_domain
    origin_id                = "S3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  # Origin - API Gateway (if different from Lambda)
  dynamic "origin" {
    for_each = local.api_domain != "" && local.api_domain != local.lambda_domain ? [1] : []
    content {
      domain_name = local.api_domain
      origin_id   = "API-gateway"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Origin - Image Optimizer Lambda
  dynamic "origin" {
    for_each = local.image_optimizer_domain != "" ? [1] : []
    content {
      domain_name = local.image_optimizer_domain
      origin_id   = "Lambda-image-optimizer"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default behavior - Lambda SSR
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "Lambda-nextjs"

    cache_policy_id          = aws_cloudfront_cache_policy.dynamic.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lambda.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Static assets behavior (_next/static)
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-assets"

    cache_policy_id = aws_cloudfront_cache_policy.static.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Public assets
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-assets"

    cache_policy_id = aws_cloudfront_cache_policy.static.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Image optimization (when enabled)
  dynamic "ordered_cache_behavior" {
    for_each = local.image_optimizer_domain != "" ? [1] : []
    content {
      path_pattern     = "/_next/image*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "Lambda-image-optimizer"

      cache_policy_id = aws_cloudfront_cache_policy.static.id

      viewer_protocol_policy = "redirect-to-https"
      compress               = true
    }
  }

  # API routes (pass to API Gateway or Lambda)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.api_domain != "" && local.api_domain != local.lambda_domain ? "API-gateway" : "Lambda-nextjs"

    cache_policy_id          = aws_cloudfront_cache_policy.dynamic.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lambda.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL/TLS
  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain && var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.enable_custom_domain && var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.enable_custom_domain && var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !(var.enable_custom_domain && var.acm_certificate_arn != "")
  }

  # WAF (optional)
  web_acl_id = var.waf_web_acl_arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cdn"
  })
}

# CloudFront Function for Security Headers
resource "aws_cloudfront_function" "security_headers" {
  name    = "${var.project_name}-${var.environment}-security-headers"
  runtime = "cloudfront-js-2.0"
  comment = "Add security headers to responses"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      
      // Add security headers to viewer request
      request.headers['x-forwarded-host'] = request.headers['host'];
      
      return request;
    }
  EOF
}

# Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.project_name}-${var.environment}-security-headers"
  comment = "Security headers policy"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}
