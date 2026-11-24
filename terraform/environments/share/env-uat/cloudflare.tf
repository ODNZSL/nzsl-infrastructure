provider "cloudflare" {}

data "cloudflare_zone" "nzslshare_nz" {
  filter = {
    name = "nzslshare.nz"
  }
}

resource "cloudflare_dns_record" "cname_uat_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "uat.nzslshare.nz"
  type    = "CNAME"
  content = "asymmetrical-newt-am8f73mpops1d13p31koxlrt.herokudns.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "mx_mxa_mg_uat_nzslshare_nz" {
  zone_id  = data.cloudflare_zone.nzslshare_nz.zone_id
  name     = "mg.uat.nzslshare.nz"
  type     = "MX"
  content  = "mxa.mailgun.org"
  priority = 10
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_mxb_mg_uat_nzslshare_nz" {
  zone_id  = data.cloudflare_zone.nzslshare_nz.zone_id
  name     = "mg.uat.nzslshare.nz"
  type     = "MX"
  content  = "mxb.mailgun.org"
  priority = 10
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "txt_spf_mg_uat_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "mg.uat.nzslshare.nz"
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "txt_dkim_mg_uat_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "mx._domainkey.mg.uat.nzslshare.nz"
  type    = "TXT"
  content = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDU48nj0pAmZmdLOOSafZlGuPvhmJzuI/7ctNa8SVQxT6B7NE0Z6WjJURakYT4/QioZCXgXOsMgFfd6qgQvfTCDYN5eLBVhKzzulY1C1rh7/CsA1heRAsCp1qqzsnHRf48FvX6T2XnUcU+BHAJCTypAS/Zuq4i827k1yClM74gJvQIDAQAB"
  proxied = false
  ttl     = 1
}
