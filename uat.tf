
terraform {
  required_providers {
    heroku = {
      source = "heroku/heroku"
      version = "5.0.2"
    }
    aws = {
      source = "hashicorp/aws"
      version = "4.13.0"
    }
  }
}

##
# The Heroku provider offers a flexible means of providing credentials for authentication.
# The following methods are supported, listed in order of precedence, and explained below:
# * Static credentials: credentials can be provided statically by adding email and api_key arguments
# * Environment variables: credentials will be sourced from the environment via the HEROKU_EMAIL and HEROKU_API_KEY environment variables respectively
# * Netrc: credentials will be sourced from the .netrc file in your home directory
provider "heroku" {}

provider "aws" {
  region = "ap-southeast-2"
}

resource "heroku_app" "app" {
	name = "nzsl_signbank_uat"
	region = "us"
	stack = "container"
}

# Create a database, and configure the app to use it
resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:hobby-basic"
}

resource "aws_s3_bucket" "media" {
  bucket = "nzsl-signbank-media-uat"
}

resource "aws_s3_bucket_acl" "media" {
  bucket = aws_s3_bucket.media.id
  acl    = "private"
}

resource "aws_iam_user" "app" {
	name = "signbank-app"
}

resource "aws_s3_bucket_policy" "media" {
	bucket = aws_s3_bucket.media.id
	policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "MediaBucket-Access",
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        "Principal": {
          "AWS": "${aws_iam_user.app.id}"
        },
        "Resource": [
          "${aws_s3_bucket.media.bucket}/*",
        ]
      }
    ]
	})
}

