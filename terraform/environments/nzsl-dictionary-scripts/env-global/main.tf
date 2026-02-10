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
}

# Enable ACLs on the bucket (required to set public-read ACLs on objects)
# By default, newer S3 buckets use "BucketOwnerEnforced" which disables ACLs entirely.
# Setting this to "BucketOwnerPreferred" allows ACLs to be set on objects while
# defaulting to bucket owner ownership when no ACL is specified.
resource "aws_s3_bucket_ownership_controls" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Allow public ACLs on individual objects while blocking public bucket policies
# This is because some dictionary exports are publicly accessible, but everything should be private by default
resource "aws_s3_bucket_public_access_block" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Deny insecure requests to the bucket
data "aws_iam_policy_document" "dictionary_data_bucket_access_policy" {
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
      aws_s3_bucket.dictionary_data.arn,
      "${aws_s3_bucket.dictionary_data.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id
  policy = data.aws_iam_policy_document.dictionary_data_bucket_access_policy.json
}
