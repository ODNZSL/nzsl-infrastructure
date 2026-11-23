terraform {
  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "env-states.tfstate"
    region = "ap-southeast-2"

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
  env_name_kebab_case  = "states"
  env_name_pascal_case = "States"

  client_name_kebab_case  = "nzsl"
  client_name_pascal_case = "NZSL"

  aws_region = "ap-southeast-2"

  default_tags = {
    Client           = local.client_name_pascal_case
    Environment      = local.env_name_pascal_case
    ProvisioningTool = "Terraform"
  }
}

################################################################################
# S3 bucket for storing Terraform states
################################################################################

resource "aws_s3_bucket" "states" {
  bucket = "nzsl-infrastructure-terraform-state"

  tags = {
    Name = "Terraform${local.env_name_pascal_case}"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "states" {
  bucket = aws_s3_bucket.states.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "states" {
  bucket = aws_s3_bucket.states.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_file_uploads" {
  bucket = aws_s3_bucket.states.bucket

  block_public_acls  = true
  ignore_public_acls = true

  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_access_policy" {
  policy_id = "EnforceSSLRequests"

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

      values = ["false"]
    }

    resources = [
      aws_s3_bucket.states.arn,
      "${aws_s3_bucket.states.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "states" {
  bucket = aws_s3_bucket.states.id
  policy = data.aws_iam_policy_document.bucket_access_policy.json
}
