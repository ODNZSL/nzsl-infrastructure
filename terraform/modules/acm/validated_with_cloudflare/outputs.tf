output "arn" {
  description = "The ARN of the certificate that was created."
  value       = aws_acm_certificate.cert.arn
}

output "domains" {
  description = "A list of all the domains that were listed on the certificate"
  value = concat(
    [aws_acm_certificate.cert.domain_name],
    tolist(aws_acm_certificate.cert.subject_alternative_names)
  )
}
