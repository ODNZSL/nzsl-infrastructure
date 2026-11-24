provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = local.default_tags
  }
}

################################################################################
# IAM user
################################################################################

resource "aws_iam_user" "app" {
  name = "nzsl-share-production-uploaded-files-bucket-access"
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy_attachment" "app_access" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.app_access.arn
}

resource "aws_iam_policy" "app_access" {
  name   = "${local.name_prefix_pascal_case}AppAccess"
  policy = data.aws_iam_policy_document.app_access.json
}

data "aws_iam_policy_document" "app_access" {
  statement {
    sid = "ListObjectsInBucket"

    actions = ["s3:ListBucket"]

    resources = [
      aws_s3_bucket.files.arn
    ]
  }

  statement {
    sid = "AllowObjectActions"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.files.arn}/*"
    ]
  }
}

################################################################################
# Files bucket
################################################################################

resource "aws_s3_bucket" "files" {
  bucket = "nzsl-share-production-uploaded-files"

  tags = {
    Name = "nzsl-share-production-uploaded-files"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls  = false
  ignore_public_acls = false

  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins = [
      "http://localhost:3000",
      "https://www.nzslshare.nz"
    ]
    allowed_headers = [
      "Content-Disposition",
      "Content-MD5",
      "Content-Type",
      "Origin"
    ]

    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "files_bucket_policy" {
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
      aws_s3_bucket.files.arn,
      "${aws_s3_bucket.files.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "files" {
  bucket = aws_s3_bucket.files.id
  policy = data.aws_iam_policy_document.files_bucket_policy.json
}
