provider "heroku" {}

resource "heroku_app" "app" {
  name   = "nzsl-share-uat"
  region = "us"
  acm    = true

  buildpacks = [
    "heroku/nodejs",
    "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/apt.tgz",
    "https://github.com/heroku/heroku-buildpack-activestorage-preview",
    "https://github.com/gaffneyc/heroku-buildpack-jemalloc.git",
    "heroku/ruby"
  ]

  config_vars = {
    CLOUDFRONT_KEY_PAIR_ID = local.files_cloudfront_key_id
    CLOUDFRONT_DOMAIN      = local.files_cloudfront_domain
  }

  organization {
    name = "nzsl"
  }
}

resource "heroku_domain" "app" {
  app_id   = heroku_app.app.id
  hostname = "uat.nzslshare.nz"
}

resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:essential-0"
}

resource "heroku_addon" "sidekiq" {
  app_id = heroku_app.app.id
  plan   = "heroku-redis:mini"
}

resource "heroku_addon" "scheduler" {
  app_id = heroku_app.app.id
  plan   = "scheduler:standard"
}
