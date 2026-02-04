terraform {
  required_version = "~> 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.13"
    }
  }

  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    region = "ap-southeast-2"
    key    = "nzsl-dictionary-scripts/env-production.tfstate"
  }
}
