provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

################################################################################
# CloudFront certificate
################################################################################

module "cert" {
  source = "../../../modules/acm/validated_with_cloudflare"

  primary_domain_name     = "share-files.nzslshare.nz"
  primary_domain_zone_id  = data.cloudflare_zone.nzslshare_nz.id
  secondary_domains       = {}
  name_prefix_pascal_case = "${local.name_prefix_pascal_case}CloudFront"

  providers = {
    aws = aws.us-east-1
  }
}

################################################################################
# CloudFront distribution
################################################################################

resource "aws_cloudfront_origin_access_control" "files" {
  name                              = aws_s3_bucket.files.bucket
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "files" {
  depends_on = [module.cert]

  origin {
    domain_name = aws_s3_bucket.files.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.files.bucket_regional_domain_name

    origin_access_control_id = aws_cloudfront_origin_access_control.files.id
  }

  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_All"

  aliases = ["share-files.nzslshare.nz"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.files.bucket_regional_domain_name

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

################################################################################
# CloudFront records
################################################################################

resource "cloudflare_dns_record" "files" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "share-files"
  content = aws_cloudfront_distribution.files.domain_name
  type    = "CNAME"
  proxied = false
  ttl     = 1
}
