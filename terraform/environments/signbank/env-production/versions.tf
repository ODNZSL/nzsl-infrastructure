terraform {
  required_version = "~> 1.14.0"

  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
