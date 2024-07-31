
variable "default_tags" {
  description = "A map of default tags that should be applied to the IAM user"
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "The name of the bucket to grant readonly access to"
  type        = string
}

variable "user_name" {
  description = "The name of the IAM user to create"
  type        = string
}
