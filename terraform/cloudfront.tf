terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  required_version = ">= 1.3.0"
}

#provider "aws" {
#  profile = "default"
#  region  = var.aws_region
#}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_bucket
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.website_bucket.json
}

resource "aws_s3_account_public_access_block" "website_bucket" {
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "website_bucket" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
# source       = "index.html"
 content_type = "text/html"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket
}

resource "aws_s3_bucket_logging""log_bucket" {
  bucket = var.website_bucket

  target_bucket =  aws_s3_bucket.log_bucket.id
  target_prefix = " "
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "S3-Console-Auto-Gen-Policy-1699224162311",
    Statement = [
      {
        Sid       = "S3PolicyStmt-DO-NOT-MODIFY-1699224162205",
        Effect    = "Allow",
        Principal = {
          Service = "logging.s3.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.log_bucket.arn}/*",
      },
    ],
  })
}

resource "aws_cloudfront_distribution" "cdn_static_site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "my cloudfront in front of the s3 bucket"

  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "techscrum-dev-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.OAC.id

  }

  aliases = [var.domain_name]

  default_cache_behavior {
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "techscrum-dev-s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:ap-southeast-2:650635451238:certificate/bc84db96-b53d-4ebb-947c-1159c243f85b"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
resource "aws_cloudfront_origin_access_control" "OAC" {
  name                              = "TechScrum-Dev OAC"
  description                       = "description of OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn_static_site.domain_name
}

data "aws_iam_policy_document" "website_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.cdn_static_site.arn]
    }
  }
}