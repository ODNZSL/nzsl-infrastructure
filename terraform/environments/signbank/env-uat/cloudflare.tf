provider "cloudflare" {}

data "cloudflare_zone" "nzsl_nz" {
  filter = {
    name = "nzsl.nz"
  }
}

resource "cloudflare_dns_record" "app" {
  zone_id = data.cloudflare_zone.nzsl_nz.zone_id
  name    = "signbank-uat"
  content = heroku_domain.app.cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
