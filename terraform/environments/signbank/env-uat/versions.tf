terraform {
  required_version = "~> 1.9.0"

  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "5.0.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    region = "ap-southeast-2"
    key    = "signbank/uat.tfstate"
  }
}
