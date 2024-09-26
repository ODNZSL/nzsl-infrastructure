variable "name_prefix_pascal_case" {
  description = "Prefix that gets added to the start of any named resource created by this module"
  type        = string
}

variable "primary_domain_name" {
  description = "The primary domain name which should be attached to the certificate"
  type        = string
}

variable "primary_domain_zone_id" {
  description = "The CloudFlare zone ID for the *primary* domain"
  type        = string
}

variable "secondary_domains" {
  description = <<-DESC
    Any secondary domain names which should be added to the certificate, mapped
    to the CloudFlare zone ID that the validation record should be created in.

    This map should *not* contain the primary domain.
  DESC
  type        = map(string)
  default     = {}
}
