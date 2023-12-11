variable "name_prefix_pascal_case" {
  description = "Prefix that gets added to the start of any named resource created by this module"
  type        = string
}

variable "github_org_name" {
  description = <<-DESC
    The name of the GitHub organisation that the GitHub Action run must be taking
    place in to be able to assume this role.
  DESC
  type        = string
}

variable "github_repo_name" {
  description = <<-DESC
    The name of the GitHub repository that the GitHub Action run must be taking
    place in to be able to assume this role.
  DESC
  type        = string
}

variable "allowed_oidc_subject_claims" {
  description = <<-DESC
    All subjects are automatically prefixed with the name of the org and the
    name of the repo e.g. `repo:ackama/some-app:`. This prefix cannot be
    removed. This means that `pull_request` in the list below becomes
    `repo:ackama/some-app:pull_request` in the eventual AWS IAM policy.

    See
    https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    for details of all the possible subject claim filters you can construct.

    Example claims:

    "ref:refs/heads/main"        # allow GA to assume this role on a branch push to 'main'
    "ref:refs/heads/production"  # allow GA to assume this role on a branch push to 'production'
    "pull_request"               # allow GA to assume this role on all pull requests
    "ref:refs/tags/my-tag"       # allow GA to assume this role on a branches tagged with `my-tag`
    "*"                          # allow GA to assume this role on any branch in response to any event (use with caution)
  DESC
  type        = list(string)
}

variable "iam_policy_document_json" {
  description = "An IAM policy document in JSON form to create and attach to the role"
  type        = string
  default     = ""
}
