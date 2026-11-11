# --- Origin certificate (opt-in) ---
#
# With create_origin_certificate = true, Terraform requests a DNS-validated
# ACM certificate for origin_domain_name. DNS is assumed to live outside AWS,
# so the module does not write the validation record: it outputs it
# (origin_certificate_validation_records) for you to create as a CNAME in your
# DNS provider, along with alb_dns_name for the origin CNAME itself.
#
# ACM will not attach an unissued certificate to a listener, so this is two
# applies:
#   1. create_origin_certificate = true. Create the validation CNAME from the
#      output. The listener keeps using acm_certificate_arn meanwhile.
#   2. wait_for_certificate_validation = true. Terraform waits for ACM to
#      issue the certificate, then puts it on the HTTPS listener.

resource "aws_acm_certificate" "origin" {
  count             = var.create_origin_certificate ? 1 : 0
  domain_name       = var.origin_domain_name
  validation_method = "DNS"

  tags = { Name = "${var.project_name}-${var.environment}-origin" }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.origin_domain_name != ""
      error_message = "create_origin_certificate requires origin_domain_name."
    }
  }
}

resource "aws_acm_certificate_validation" "origin" {
  count           = var.create_origin_certificate && var.wait_for_certificate_validation ? 1 : 0
  certificate_arn = aws_acm_certificate.origin[0].arn
}

locals {
  acm_certificate_arn = length(aws_acm_certificate_validation.origin) > 0 ? aws_acm_certificate_validation.origin[0].certificate_arn : var.acm_certificate_arn
}
