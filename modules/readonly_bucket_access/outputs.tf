output "aws_iam_access_key_id" {
  value     = aws_iam_access_key.access.id
  sensitive = true
}

output "aws_iam_secret_access_key" {
  value     = aws_iam_access_key.access.secret
  sensitive = true
}
