# `readonly_bucket_access`

Creates an IAM user and keypair that has read-only access to a given S3 bucket.

## Usage

```terraform
module "bucket_access" {
  source = "modules/readonly_bucket_access"

  user_name = "bucket-user"
  bucket_name = "bucket"
}

output "aws_access_key_id" {
  description = "The AWS access key ID for readonly bucket access"
  value       = module.bucket_access.aws_access_key_id
}

output "aws_secret_access_key" {
  description = "The AWS secret access key for readonly bucket access"
  value       = module.bucket_access.aws_secret_access_key
}
```