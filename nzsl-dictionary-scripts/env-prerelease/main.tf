terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.13"
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

  default_tags {
    tags = local.default_tags
  }
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

data "aws_iam_policy_document" "write_only_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::nzsl-signbank-media-uat/dictionary-exports/nzsl.db"
    ]
  }
}


module "bucket_access" {
  source      = "../../modules/readonly_bucket_access"
  user_name   = "${local.app_name_pascal_case}User"
  bucket_name = "nzsl-signbank-media-uat"
}

module "github_oidc_role" {
  source = "../../modules/github_oidc_role"

  name_prefix_pascal_case     = local.app_name_pascal_case
  github_org_name             = "ODNZSL"
  github_repo_name            = "nzsl-dictionary-scripts"
  allowed_oidc_subject_claims = ["environment:Prerelease"]
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