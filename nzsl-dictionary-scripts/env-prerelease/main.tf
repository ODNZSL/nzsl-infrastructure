
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }
  }

  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    region = "ap-southeast-2"
    key    = "nzsl-dictionary-scripts/env-prerelease.tfstate"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

locals {
  app_name_pascal_case = "NZSLDictionaryScriptsPrereleaseDeployment"
  default_tags = {
    Environment      = "Prerelease"
    Client           = "DSRU"
    Project          = "NZSL Dictionary Scripts"
    ProvisioningTool = "Terraform"
  }
}

module "bucket_access" {
  source       = "../../modules/readonly_bucket_access"
  default_tags = local.default_tags
  user_name    = "${local.app_name_pascal_case}User"
  bucket_name  = "nzsl-signbank-media-uat"
}

module "github_oidc_role" {
  source = "../../modules/github_oidc_role"

  name_prefix_pascal_case     = local.app_name_pascal_case
  github_org_name             = "odnzsl"
  github_repo_name            = "nzsl-dictionary-scripts"
  allowed_oidc_subject_claims = ["environment:Prerelease"]
}

output "aws_access_key_id" {
  description = "The AWS access key ID for readonly bucket access"
  value       = module.bucket_access.aws_iam_access_key_id
  sensitive   = true
}

output "aws_secret_access_key" {
  description = "The AWS secret access key for readonly bucket access"
  value       = module.bucket_access.aws_iam_secret_access_key
  sensitive   = true
}