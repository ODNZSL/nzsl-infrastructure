terraform {
  backend "s3" {
    region = "ap-southeast-2"
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "online/env-assets"

    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = local.default_tags
  }
}

################################################################################
# Module Local Variables
################################################################################

locals {
  # Application names should be kept relatively short as they're used to prefix
  # resources which regularly have low limits on name length.
  #
  # Generally we try and go with snappy pseudonyms or acronyms where possible
  app_name_kebab_case  = "online"
  app_name_pascal_case = "Online"

  env_name_kebab_case  = "assets"
  env_name_pascal_case = "Assets"

  client_name_kebab_case  = "nzsl"
  client_name_pascal_case = "NZSL"

  default_tags = {
    Application      = local.app_name_pascal_case
    Client           = local.client_name_pascal_case
    Environment      = local.env_name_pascal_case
    ProvisioningTool = "Terraform"
  }
}

################################################################################
# Assets bucket
################################################################################

resource "aws_s3_bucket" "assets" {
  bucket = "nzsl-assets"

  tags = {
    Name = "${local.app_name_pascal_case}Assets"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls  = false
  ignore_public_acls = false

  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "bucket_access_policy" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }
}
