provider "heroku" {}

resource "heroku_app" "app" {
  name   = "nzsl-staging"
  region = "us"
  acm    = true

  buildpacks = [
    "https://github.com/jontewks/puppeteer-heroku-buildpack",
    "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/apt.tgz",
    "https://github.com/gaffneyc/heroku-buildpack-jemalloc.git",
    "heroku/nodejs",
    "heroku/ruby"
  ]

  organization {
    name = "nzsl"
  }
}

resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:essential-0"
}

resource "heroku_addon" "cache" {
  app_id = heroku_app.app.id
  plan   = "memcachedcloud:30"
}

resource "heroku_addon" "apm" {
  app_id = heroku_app.app.id
  plan   = "newrelic:wayne"
}

resource "heroku_addon" "scheduler" {
  app_id = heroku_app.app.id
  plan   = "scheduler:standard"
}

resource "heroku_addon" "email" {
  app_id = heroku_app.app.id
  plan   = "sendgrid:starter"
}
