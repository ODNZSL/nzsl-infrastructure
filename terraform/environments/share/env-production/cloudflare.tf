provider "cloudflare" {}

data "cloudflare_zone" "nzslshare_nz" {
  filter = {
    name = "nzslshare.nz"
  }
}

resource "cloudflare_dns_record" "cname_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "nzslshare.nz"
  type    = "CNAME"
  content = "www.nzslshare.nz"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "cname_www_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "www.nzslshare.nz"
  type    = "CNAME"
  content = "environmental-ridge-w0cgebziv4gsxjt0jo71xkgx.herokudns.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "mx_mxa_mg_nzslshare_nz" {
  zone_id  = data.cloudflare_zone.nzslshare_nz.zone_id
  name     = "mg.nzslshare.nz"
  type     = "MX"
  content  = "mxa.mailgun.org"
  priority = 10
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_mxb_mg_nzslshare_nz" {
  zone_id  = data.cloudflare_zone.nzslshare_nz.zone_id
  name     = "mg.nzslshare.nz"
  type     = "MX"
  content  = "mxb.mailgun.org"
  priority = 10
  proxied  = false
  ttl      = 1
}

resource "cloudflare_dns_record" "txt_spf_mg_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "mg.nzslshare.nz"
  type    = "TXT"
  content = "v=spf1 include:mailgun.org ~all"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "txt_dkim_mg_nzslshare_nz" {
  zone_id = data.cloudflare_zone.nzslshare_nz.zone_id
  name    = "k1._domainkey.mg.nzslshare.nz"
  type    = "TXT"
  content = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8S981mEUaS4Gg5WcTyNQ5A7eruF3rWS7TIxsuqBpN8KVugFBE8I6phIlrd15Ey2jyWVQZ9oMcWG/Ksnped5VkQdc9KeOWiQYdoT4An1n9bINWHGR0a+hARxqz+MPJiFuEETmRqij2wNTzHYgYeHT/PRyEndXWlI+LUPbWS8YxqwIDAQAB"
  proxied = false
  ttl     = 1
}
