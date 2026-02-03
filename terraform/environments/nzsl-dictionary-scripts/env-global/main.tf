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
    key    = "nzsl-dictionary-scripts/env-global.tfstate"
  }
}

provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = local.default_tags
  }
}

locals {
  bucket_name = "nzsl-dictionary-data"
  default_tags = {
    Environment      = "Global"
    Client           = "DSRU"
    Project          = "NZSL Dictionary Scripts"
    ProvisioningTool = "Terraform"
  }
}

# Create dedicated S3 bucket for dictionary exports
resource "aws_s3_bucket" "dictionary_data" {
  bucket = local.bucket_name
  tags   = local.default_tags
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}


# Set bucket ACL to private
resource "aws_s3_bucket_acl" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id
  acl    = "private"
}

output "bucket_name" {
  description = "The name of the S3 bucket for dictionary exports"
  value       = aws_s3_bucket.dictionary_data.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket for dictionary exports"
  value       = aws_s3_bucket.dictionary_data.arn
}
