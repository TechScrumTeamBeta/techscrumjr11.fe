terraform {
  required_version = ">= 1.3.0"
}

resource "aws_s3_bucket" "website_bucket" {
  provider = aws.primary_region
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

resource "aws_s3_bucket" "website_bucket_ha" {
  provider = aws.secondary_region
  bucket = var.website_bucket_ha
}

resource "aws_s3_bucket_policy" "website_bucket_ha_policy" {
  provider = aws.secondary_region
  bucket = aws_s3_bucket.website_bucket_ha.id
  policy = data.aws_iam_policy_document.website_bucket_ha.json
}

resource "aws_s3_account_public_access_block" "website_bucket_ha" {
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3control_multi_region_access_point" "multibucket" {
  details {
    name = "multibucket"

    region {
      bucket = aws_s3_bucket.website_bucket.id
    }

    region {
      bucket = aws_s3_bucket.website_bucket_ha.id
    }
  }
}

resource "aws_cloudfront_origin_access_control" "OAC" {
  name                              = "TechScrum-QA OAC"
  description                       = "description of TechScrum-QA OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "cloudfront of TechScurm-QA"

  origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = "primaryS3"
    }

    member {
      origin_id = "failoverS3"
    }
  }

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "primaryS3"
    origin_access_control_id = aws_cloudfront_origin_access_control.OAC.id
   
  }

  origin {
    domain_name = aws_s3_bucket.website_bucket_ha.bucket_regional_domain_name
    origin_id   = "failoverS3"
    origin_access_control_id = aws_cloudfront_origin_access_control.OAC.id
  }


  aliases = [var.domain_name]

  default_cache_behavior {
    
    # Using the CachingDisabled managed policy ID:
    cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "groupS3"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:650635451238:certificate/81565df2-3631-4165-8d8d-3bfcf3325387"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_iam_policy_document" "website_bucket" {
  provider = aws.secondary_region
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
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

data "aws_iam_policy_document" "website_bucket_ha" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket_ha.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}
