provider "aws" {
  region = "ap-southeast-2"
}

################################################################################
# Media bucket
################################################################################

resource "aws_s3_bucket" "media" {
  bucket = "nzsl-signbank-media-uat"
  tags   = var.default_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls  = false
  ignore_public_acls = false

  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "media" {
  bucket = aws_s3_bucket.media.id
  acl    = "private"
}

data "aws_iam_policy_document" "media_bucket_policy" {
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
      aws_s3_bucket.media.arn,
      "${aws_s3_bucket.media.arn}/*",
    ]
  }

  statement {
    sid     = "AllowCloudFrontServicePrincipal"
    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.media.arn}/*"]

    condition {
      variable = "aws:SourceArn"
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.files.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "files" {
  bucket = aws_s3_bucket.media.id
  policy = data.aws_iam_policy_document.media_bucket_policy.json
}

################################################################################
# IAM user
################################################################################

resource "aws_iam_user" "app" {
  name = "signbank-app-uat"
  tags = var.default_tags
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy_attachment" "media" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.media.arn
}

resource "aws_iam_policy" "media" {
  name        = "SignbankUATMediaBucketAccessPolicy"
  description = "IAM policy for accessing the media bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SignbankUATMediaBucketAccess",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:DeleteObjectTagging"
        ],
        "Resource" : [
          "${aws_s3_bucket.media.arn}/*"
        ]
      }
    ]
  })
}
