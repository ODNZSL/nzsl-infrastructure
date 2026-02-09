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
      "arn:aws:s3:::${local.bucket_name}/production/*",
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
