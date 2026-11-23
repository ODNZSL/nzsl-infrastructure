output "bucket_name" {
  description = "The name of the S3 bucket for dictionary exports"
  value       = aws_s3_bucket.dictionary_data.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket for dictionary exports"
  value       = aws_s3_bucket.dictionary_data.arn
}
