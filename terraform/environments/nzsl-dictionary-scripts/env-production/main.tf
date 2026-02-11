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

provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = local.default_tags
  }
}

locals {
  app_name_pascal_case = "NZSLDictionaryScriptsProductionDeployment"
  bucket_name          = "nzsl-dictionary-data"
  default_tags = {
    Environment      = "Production"
    Client           = "DSRU"
    Project          = "NZSL Dictionary Scripts"
    ProvisioningTool = "Terraform"
  }
}

data "aws_iam_policy_document" "write_only_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      # New dedicated bucket
      "arn:aws:s3:::${local.bucket_name}/dictionary-exports/public/*",
      # Legacy bucket access (temporary during migration)
      "arn:aws:s3:::nzsl-signbank-media-production/dictionary-exports/production/*"
    ]
  }
}

module "bucket_access" {
  source       = "../../../modules/readonly_bucket_access"
  user_name    = "${local.app_name_pascal_case}User"
  bucket_name  = local.bucket_name
  default_tags = local.default_tags
}

module "github_oidc_role" {
  source = "../../../modules/github_oidc_role"

  name_prefix_pascal_case     = local.app_name_pascal_case
  github_org_name             = "ODNZSL"
  github_repo_name            = "nzsl-dictionary-scripts"
  allowed_oidc_subject_claims = ["environment:Production"]
  iam_policy_document_json    = data.aws_iam_policy_document.write_only_access.json
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
