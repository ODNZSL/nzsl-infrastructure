provider "heroku" {}

resource "heroku_app" "app" {
  name   = "nzsl-signbank-production"
  region = "us"
  stack  = "container"

  config_vars = {
    AWS_CLOUDFRONT_KEY_PAIR_ID = local.files_cloudfront_key_id
    AWS_CLOUDFRONT_DOMAIN      = local.files_cloudfront_domain
    AWS_STORAGE_BUCKET_NAME    = aws_s3_bucket.media.id,
    ALLOWED_HOSTS              = "signbank.${data.cloudflare_zone.nzsl_nz.name}"
    DJANGO_SETTINGS_MODULE     = "signbank.settings.production"
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
  hostname = "signbank.${data.cloudflare_zone.nzsl_nz.name}"

  sni_endpoint_id = "a3afa265-65bc-49dd-a8ad-c9788d06b2f2"
}

# Create a database, and configure the app to use it
resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:essential-0"
}
