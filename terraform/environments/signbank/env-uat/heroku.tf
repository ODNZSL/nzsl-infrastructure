provider "heroku" {}

resource "heroku_app" "app" {
  name   = "nzsl-signbank-uat"
  region = "us"
  stack  = "container"

  config_vars = {
    AWS_CLOUDFRONT_KEY_PAIR_ID = local.files_cloudfront_key_id
    AWS_CLOUDFRONT_DOMAIN      = local.files_cloudfront_domain
    AWS_STORAGE_BUCKET_NAME    = aws_s3_bucket.media.id
  }

  sensitive_config_vars = {
    "AWS_ACCESS_KEY_ID"     = aws_iam_access_key.app.id,
    "AWS_SECRET_ACCESS_KEY" = aws_iam_access_key.app.secret
  }

  organization {
    name = "nzsl"
  }
}

resource "heroku_domain" "app" {
  app_id   = heroku_app.app.id
  hostname = "signbank-uat.${data.cloudflare_zone.nzsl_nz.name}"

  sni_endpoint_id = "0517a9a2-6600-4402-9aa8-17b9e9dc1853"
}

# Create a database, and configure the app to use it
resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:essential-0"
}
