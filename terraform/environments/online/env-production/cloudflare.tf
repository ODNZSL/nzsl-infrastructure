provider "cloudflare" {}

data "cloudflare_zone" "nzsl_nz" {
  filter = {
    name = "nzsl.nz"
  }
}

resource "cloudflare_dns_record" "cname_www_nzsl_nz" {
  zone_id = data.cloudflare_zone.nzsl_nz.zone_id
  name    = "www"
  content = "nzsl.herokuapp.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "cname_nzsl_nz" {
  zone_id = data.cloudflare_zone.nzsl_nz.zone_id
  name    = "@"
  content = "www.nzsl.nz"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
