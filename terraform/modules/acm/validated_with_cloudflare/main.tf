locals {
  domain_to_zone_id = merge(
    { (var.primary_domain_name) : var.primary_domain_zone_id },
    var.secondary_domains
  )
}

# Create an ACM Certificate validated by DNS
resource "aws_acm_certificate" "cert" {
  domain_name               = var.primary_domain_name
  subject_alternative_names = keys(var.secondary_domains)
  validation_method         = "DNS"

  tags = {
    Name = "${var.name_prefix_pascal_case}Certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  value           = trimsuffix(each.value.record, ".")
  ttl             = 1
  type            = each.value.type
  zone_id         = local.domain_to_zone_id[each.value.domain]
  proxied         = false
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in cloudflare_record.cert : record.hostname]
}
