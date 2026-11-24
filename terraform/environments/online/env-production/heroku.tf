provider "heroku" {}

resource "heroku_app" "app" {
  name   = "nzsl"
  region = "us"
  acm    = true

  buildpacks = [
    "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/apt.tgz",
    "https://github.com/gaffneyc/heroku-buildpack-jemalloc.git",
    "heroku/nodejs",
    "https://github.com/jontewks/puppeteer-heroku-buildpack",
    "heroku/ruby"
  ]

  organization {
    name = "nzsl"
  }
}

resource "heroku_domain" "app" {
  app_id   = heroku_app.app.id
  hostname = "www.nzsl.nz"
}

resource "heroku_domain" "app2" {
  app_id   = heroku_app.app.id
  hostname = "nzsl.vuw.ac.nz"
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
