output "aws_access_key_id" {
  description = "The AWS access key ID for readonly bucket access"
  value       = module.bucket_access.aws_iam_access_key_id
  sensitive   = true
}

output "aws_secret_access_key" {
  description = "The AWS secret access key for readonly bucket access"
  value       = module.bucket_access.aws_iam_secret_access_key
  sensitive   = true
}
