
terraform {
  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "5.0.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    region = "ap-southeast-2"
    key    = "signbank/uat.tfstate"
  }
}

variable "default_tags" {
  type        = map(any)
  description = "Common tags applied to all AWS resources"
  default = {
    Environment      = "uat"
    Client           = "DSRU"
    Project          = "NZSL Signbank"
    ProvisioningTool = "Terraform"
  }
}

##
# The Heroku provider offers a flexible means of providing credentials for authentication.
# The following methods are supported, listed in order of precedence, and explained below:
# * Static credentials: credentials can be provided statically by adding email and api_key arguments
# * Environment variables: credentials will be sourced from the environment via the HEROKU_EMAIL and HEROKU_API_KEY environment variables respectively
# * Netrc: credentials will be sourced from the .netrc file in your home directory
provider "heroku" {}

##
# The Cloudflare provider offers different means of providing credentials for authentication:
# * email - (Optional) The email associated with the account.
#           This can also be specified with the CLOUDFLARE_EMAIL shell environment variable.
# * api_key - (Optional) The Cloudflare API key.
#             This can also be specified with the CLOUDFLARE_API_KEY shell environment variable.
# * api_token - (Optional) The Cloudflare API Token. This can also be specified with the CLOUDFLARE_API_TOKEN shell environment variable.
# .             This is an alternative to email+api_key. If both are specified, api_token will be used over email+api_key fields.
provider "cloudflare" {}

provider "aws" {
  region = "ap-southeast-2"
}

data "cloudflare_zone" "root" {
  name = "nzsl.nz"
}
resource "heroku_app" "app" {
  name   = "nzsl-signbank-uat"
  region = "us"
  stack  = "container"

  config_vars = {
    "AWS_STORAGE_BUCKET_NAME" = aws_s3_bucket.media.id
  }

  sensitive_config_vars = {
    "AWS_ACCESS_KEY_ID"     = aws_iam_access_key.app.id,
    "AWS_SECRET_ACCESS_KEY" = aws_iam_access_key.app.secret
  }

  organization {
    name = "nzsl"
  }
}

resource "heroku_domain" "app" {
  app_id   = heroku_app.app.id
  hostname = "signbank-uat.${data.cloudflare_zone.root.name}"
}

resource "cloudflare_record" "app" {
  zone_id = data.cloudflare_zone.root.zone_id
  name    = "signbank-uat"
  value   = heroku_domain.app.cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Create a database, and configure the app to use it
resource "heroku_addon" "database" {
  app_id = heroku_app.app.id
  plan   = "heroku-postgresql:essential-0"
}

resource "aws_s3_bucket" "media" {
  bucket = "nzsl-signbank-media-uat"
  tags   = var.default_tags
}

resource "aws_s3_bucket_acl" "media" {
  bucket = aws_s3_bucket.media.id
  acl    = "private"
}

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
          "s3:PutObjectAcl"
        ],
        "Resource" : [
          "${aws_s3_bucket.media.arn}/*"
        ]
      }
    ]
  })
}
