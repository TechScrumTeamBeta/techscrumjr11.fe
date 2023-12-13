provider "aws" {
  alias = "acm"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Environment = "TechScrum Cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "cert_validation" {
    for_each = {
      for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }

    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    type            = each.value.type
    zone_id         = var.zone_id
    ttl             = 60
}
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

data "aws_route53_zone" "existing_zone" {
  name         = var.existing_zone
  private_zone = false
}

#resource "aws_route53_record" "www" {
#  zone_id = var.zone_id
#  name    = "www.${var.domain_name}"
#  type    = "A"
#  alias {
#    name                   = aws_cloudfront_distribution.cdn_static_site.domain_name
#    zone_id                = aws_cloudfront_distribution.cdn_static_site.hosted_zone_id
#    evaluate_target_health = false
#  }
#}

resource "aws_route53_record" "apex" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
