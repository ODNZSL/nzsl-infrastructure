# `acm/validated_with_cloudflare`

Creates a validated certificate in AWS Certificate Manager (ACM) that can be
used by other AWS services to allow HTTPS, and which is validated using DNS
records that are automatically created in the respective CloudFlare zones for the
domains listed on the certificate.

## Usage

```terraform
data "cloudflare_zone" "my-site_com" {
  name = "my-site.com"
}
data "cloudflare_zone" "my-site_org" {
  name = "my-site.org"
}

module "load_balancer_cert" {
  source = "../../modules/acm/validated_with_cloudflare"

  name_prefix_pascal_case = "${local.name_prefix_pascal_case}LoadBalancer"

  primary_domain_name    = "my-site.com"
  primary_domain_zone_id = data.cloudflare_zone.my-site_com.id

  secondary_domains = {
    "www.my-site.com" : data.cloudflare_zone.my-site_com.id
    "my-site.org" : data.cloudflare_zone.my-site_com.id
    "www.my-site.org" : data.cloudflare_zone.my-site_com.id
  }
}
```
