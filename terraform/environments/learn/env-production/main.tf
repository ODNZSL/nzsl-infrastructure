terraform {
  required_version = ">= 1.0"

  backend "s3" {
    region = "ap-southeast-2"
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "learnnzsl-production"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

provider "cloudflare" {}

################################################################################
# Module Local Variables
################################################################################

locals {
  # Application names should be kept relatively short as they're used to prefix
  # resources which regularly have low limits on name length.
  #
  # Generally we try and go with snappy pseudonyms or acronyms where possible
  app_name_kebab_case  = "learn-nzsl"
  app_name_pascal_case = "LearnNZSL"

  client_name_kebab_case  = "nzsl"
  client_name_pascal_case = "NZSL"

  aws_region = "ap-southeast-2"

  default_tags = {
    Application      = local.app_name_pascal_case
    Client           = local.client_name_pascal_case
    ProvisioningTool = "Terraform"
  }
}

################################################################################
# S3 Bucket for hosting
################################################################################

resource "aws_s3_bucket" "hosting" {
  bucket = local.app_name_kebab_case

  tags = {
    Name = "${local.app_name_pascal_case}Hosting"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  block_public_acls  = true
  ignore_public_acls = true

  block_public_policy     = false
  restrict_public_buckets = false # todo: false
}

data "aws_iam_policy_document" "bucket_access_policy" {
  policy_id = "EnforceSSLRequests"

  statement {
    sid     = "AllowAccessToSite"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = ["true"]
    }

    resources = [
      "${aws_s3_bucket.hosting.arn}/*"
    ]
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = ["false"]
    }

    resources = [
      aws_s3_bucket.hosting.arn,
      "${aws_s3_bucket.hosting.arn}/*"
    ]
  }

  statement {
    sid = "AllowCloudFrontServicePrincipal"

    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.hosting.arn}/*"]

    condition {
      variable = "AWS:SourceArn"
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "hosting" {
  bucket = aws_s3_bucket.hosting.id
  policy = data.aws_iam_policy_document.bucket_access_policy.json
}

################################################################################
# DNS zone and records
################################################################################

data "cloudflare_zone" "root" {
  name = "nzsl.nz"
}

module "cert" {
  source = "../../../modules/acm/validated_with_cloudflare"

  primary_domain_name     = "learn.nzsl.nz"
  primary_domain_zone_id  = data.cloudflare_zone.root.id
  name_prefix_pascal_case = "${local.app_name_pascal_case}CloudFront"

  providers = {
    aws = aws.us-east-1
  }
}

resource "cloudflare_record" "app" {
  zone_id = data.cloudflare_zone.root.zone_id
  name    = "learn"
  value   = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

################################################################################
# Cloudfront distribution
################################################################################

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = aws_s3_bucket.hosting.bucket_regional_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.hosting.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.hosting.bucket_regional_domain_name

    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_All"
  default_root_object = "index.html"

  aliases = [
    "learn.nzsl.nz"
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.hosting.bucket_regional_domain_name

    viewer_protocol_policy = "redirect-to-https"

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
