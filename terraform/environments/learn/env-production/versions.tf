terraform {
  required_version = "~> 1.9.0"

  backend "s3" {
    region = "ap-southeast-2"
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "learnnzsl-production"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
