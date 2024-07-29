output "name_full_pascal_case" {
  value = local.name_full_pascal_case
}

output "role_name" {
  value = aws_iam_role.main.name
}

output "role_id" {
  value = aws_iam_role.main.unique_id
}

output "arn" {
  value = aws_iam_role.main.arn
}

output "oidc_subject_claims" {
  description = <<-DESC
    The value(s) that token.actions.githubusercontent.com:sub must equal when
    trying to assume the role as a federated user.

    Useful for debugging, to ensure that the value is correct.
  DESC
  value       = local.oidc_subject_claims
}
