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

# Enable ACLs so objects can have public-read ACL set (but only in public folder per policy)
resource "aws_s3_bucket_ownership_controls" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
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

# Bucket policy: enforce SSL and restrict ACL setting to public folder only
data "aws_iam_policy_document" "dictionary_data_bucket_access_policy" {
  policy_id = "DictionaryDataBucketPolicy"

  # Deny insecure requests (HTTP) to the bucket
  statement {
    sid     = "DenyInsecureTransport"
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

  # Allow setting public-read ACL on objects in the public folder only
  # By only allowing public-read ACL for public/*, it is implicitly denied elsewhere
  statement {
    sid    = "AllowPublicReadAclInPublicFolder"
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["public-read"]
    }

    resources = [
      "${aws_s3_bucket.dictionary_data.arn}/public/*"
    ]
  }

  # Allow setting other ACLs (private, bucket-owner-read, etc.) on any object
  # This allows normal ACL management while restricting only public-read ACLs
  statement {
    sid    = "AllowOtherAcls"
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-acl"
      values   = ["public-read"]
    }

    resources = [
      "${aws_s3_bucket.dictionary_data.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "dictionary_data" {
  bucket = aws_s3_bucket.dictionary_data.id
  policy = data.aws_iam_policy_document.dictionary_data_bucket_access_policy.json
}
