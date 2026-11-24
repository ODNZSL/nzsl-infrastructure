terraform {
  backend "s3" {
    region = "ap-southeast-2"
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "learn/env-production.tfstate"
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
# S3 Buckets for hosting and videos
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

  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "videos" {
  bucket = "${local.app_name_kebab_case}-videos"

  tags = {
    Name = "${local.app_name_pascal_case}Videos"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "videos" {
  bucket = aws_s3_bucket.videos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "videos" {
  bucket = aws_s3_bucket.videos.id

  block_public_acls  = true
  ignore_public_acls = true

  block_public_policy     = true
  restrict_public_buckets = true
}

locals {
  cdn_buckets = {
    (aws_s3_bucket.hosting.id) = aws_s3_bucket.hosting.arn
    (aws_s3_bucket.videos.id)  = aws_s3_bucket.videos.arn
  }
}

data "aws_iam_policy_document" "bucket_access_policy" {
  for_each = local.cdn_buckets

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
      values   = ["false"]
    }

    resources = [
      each.value,
      "${each.value}/*",
    ]
  }

  statement {
    sid     = "AllowCloudFrontServicePrincipal"
    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = ["${each.value}/*"]

    condition {
      variable = "AWS:SourceArn"
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_access_policy" {
  for_each = local.cdn_buckets

  bucket = each.key
  policy = data.aws_iam_policy_document.bucket_access_policy[each.key].json
}

################################################################################
# DNS zone and records
################################################################################

data "cloudflare_zone" "nzsl_nz" {
  filter = {
    name = "nzsl.nz"
  }
}

data "cloudflare_zone" "learnnzsl_nz" {
  filter = {
    name = "learnnzsl.nz"
  }
}

module "cert" {
  source = "../../../modules/acm/validated_with_cloudflare"

  primary_domain_name    = "learn.nzsl.nz"
  primary_domain_zone_id = data.cloudflare_zone.nzsl_nz.id
  secondary_domains = {
    "learnnzsl.nz" : data.cloudflare_zone.learnnzsl_nz.id,
    "www.learnnzsl.nz" : data.cloudflare_zone.learnnzsl_nz.id
  }
  name_prefix_pascal_case = "${local.app_name_pascal_case}CloudFront"

  providers = {
    aws = aws.us-east-1
  }
}

resource "cloudflare_dns_record" "learn_nzsl_nz_cname" {
  zone_id = data.cloudflare_zone.nzsl_nz.zone_id
  name    = "learn"
  content = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "learnnzsl_nz_cname" {
  zone_id = data.cloudflare_zone.learnnzsl_nz.zone_id
  name    = "@"
  content = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www_learnnzsl_nz_cname" {
  zone_id = data.cloudflare_zone.learnnzsl_nz.zone_id
  name    = "www"
  content = aws_cloudfront_distribution.cdn.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_ruleset" "redirect_to_learn_nzsl_nz" {
  zone_id = data.cloudflare_zone.learnnzsl_nz.id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    description = "Redirect to learn.nzsl.nz"
    action      = "redirect"
    enabled     = true
    expression  = "true"

    action_parameters = {
      from_value = {
        preserve_query_string = true
        status_code           = 302

        target_url = {
          expression = "concat(\"https://learn.nzsl.nz\",http.request.uri.path)"
        }
      }
    }
  }]
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

resource "aws_cloudfront_origin_access_control" "videos" {
  name                              = aws_s3_bucket.videos.bucket_regional_domain_name
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

  origin {
    domain_name = aws_s3_bucket.videos.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.videos.bucket_regional_domain_name

    origin_access_control_id = aws_cloudfront_origin_access_control.videos.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_All"
  default_root_object = "index.html"

  aliases = [
    "learn.nzsl.nz",
    "learnnzsl.nz",
    "www.learnnzsl.nz"
  ]

  ordered_cache_behavior {
    path_pattern     = "/videos/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.videos.bucket_regional_domain_name

    viewer_protocol_policy = "redirect-to-https"

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

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
