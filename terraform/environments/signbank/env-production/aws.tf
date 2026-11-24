provider "aws" {
  region = "ap-southeast-2"
}

################################################################################
# Media bucket
################################################################################

resource "aws_s3_bucket" "media" {
  bucket = "nzsl-signbank-media-production"
  tags   = var.default_tags
}

resource "aws_s3_bucket_acl" "media" {
  bucket = aws_s3_bucket.media.id
  acl    = "private"
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [
      "http://localhost:3000",
      "https://*.nzslshare.nz",
      "https://*.nzsl.nz",
      "https://nzsl-staging.herokuapp.com"
    ]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_iam_user" "app" {
  name = "signbank-app-production"
  tags = var.default_tags
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

resource "null_resource" "schedule_backups" {
  provisioner "local-exec" {
    command = "heroku pg:backups:schedule --at '02:00 Pacific/Auckland'"
    environment = {
      HEROKU_APP = "${heroku_app.app.name}"
    }
  }
}

resource "aws_iam_user_policy_attachment" "media" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.media.arn
}

resource "aws_iam_policy" "media" {
  name        = "SignbankProductionMediaBucketAccessPolicy"
  description = "IAM policy for accessing the media bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SignbankProductionMediaBucketAccess",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        "Resource" : [
          "${aws_s3_bucket.media.arn}/*"
        ]
      }
    ]
  })
}
