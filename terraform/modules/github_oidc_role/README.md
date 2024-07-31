# `github_oidc_role`

Creates an IAM role that can be assumed by GitHub Actions using GitHub's OIDC
provider, provided that the workflow run is for the specified organisation,
repository, and branch.

- See
  [here](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
  for details on how this works
- See
  [here](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
  for details on how this works with AWS

> **Note**
>
> An OpenID Connect provider must exist in IAM with a URL of
> `https://token.actions.githubusercontent.com`.

## Usage

```terraform
# this exists at the account level, and is looked up by the module based on its URL
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # the thumbprint should never change unless GitHub change their certificate chain
  # see https://stackoverflow.com/questions/69247498 on how you can check the value
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gha_access_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

    resources = ["*"]
  }
}

module "gha_staging_role" {
  source = "modules/github_oidc_role"

  name_prefix_pascal_case = "${local.app_name_pascal_case}Staging"

  github_org_name             = "ackama"
  github_repo_name            = "my-repo"
  allowed_oidc_subject_claims = ["ref:refs/heads/main"]

  iam_policy_document_json = data.aws_iam_policy_document.gha_access_policy.json
}

output "gha_staging_role_arn" {
  description = "The ARN to use for the role-to-assume input in GHA workflows"
  value       = module.gha_staging_role.arn
}
```

Sample workflow:

```yaml
# github.com/ackama/my-repo/blob/main/.github/workflows/describe-instances.yml
on:
  push:
    branches: [main]

jobs:
  describe-instances:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          # this is the value of `terraform output gha_staging_role_arn`
          role-to-assume: arn:aws:iam::1234567890:role/MyAppStagingGHARole
          aws-region: ap-southeast-2
      - run: aws ec2 describe-instances --query 'Reservations[].Instances[]'
```

You can also attach policies using the `aws_iam_role_policy_attachment` resource
and the `role_name` output attribute:

```terraform
module "gha_role" {
  source = "modules/github_oidc_role"

  name_prefix_pascal_case = "${local.app_name_pascal_case}${local.env_name_pascal_case}"

  github_org_name             = "ackama"
  github_repo_name            = "my-repo"
  allowed_oidc_subject_claims = ["ref:refs/heads/main"]
}

data "aws_iam_policy_document" "allow_uploading_to_s3" {
  statement {
    sid = "ListObjectsInBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      local.static_site_bucket_arn
    ]
  }

  statement {
    sid = "AllowObjectActions"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "${local.static_site_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "gha_s3_access" {
  description = "Read and write access to the static site hosting bucket"
  name        = "${local.app_name_pascal_case}${local.env_name_pascal_case}StaticSiteBucketAccess"

  policy = data.aws_iam_policy_document.allow_uploading_to_s3.json
}

resource "aws_iam_role_policy_attachment" "gha_s3_access" {
  role       = module.gha_role.role_name
  policy_arn = aws_iam_policy.gha_s3_access.arn
}

output "gha_role_arn" {
  description = "The ARN to use for the role-to-assume input in GHA workflows"
  value       = module.gha_role.arn
}
```

Sample GHA workflow:

```yaml
# github.com/ackama/my-repo/blob/main/.github/workflows/deploy.yml
on:
  push:
    branches: [main]

jobs:
  deploy-to-s3:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v3
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          # this is the value of `terraform output gha_role_arn`
          role-to-assume: arn:aws:iam::1234567890:role/MyAppStagingGHARole
          aws-region: ap-southeast-2
      - run: aws s3 cp ./index.html s3://my-app-staging-bucket/
```

### Locking the role to certain Github Actions events (e.g. branch push, PR etc.)

Github OIDC uses the "subject claim" string to lock down what kinds of Github
Actions events are allowed to assume the role. We should endeavour to lock each
role down as much as possible.

```terraform
module "gha_role" {
  source = "modules/github_oidc_role"

  # ...

  allowed_oidc_subject_claims = [
    # All subjects are automatically prefixed with the name of the org and the
    # name of the repo e.g. `repo:ackama/some-app:`. This prefix cannot be
    # removed. This means that `pull_request` in the list below becomes
    # `repo:ackama/some-app:pull_request` in the eventual AWS IAM policy.
    #
    # See
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    # for details of all the possible subject claim filters you can construct.
    #
    # You should try to lock down the role as much as possible.
    #
    "ref:refs/heads/main",        # allow GA to assume this role on a branch push to 'main'
    "ref:refs/heads/production",  # allow GA to assume this role on a branch push to 'production'
    "pull_request"                # allow GA to assume this role on all pull requests
    "ref:refs/tags/my-tag",       # allow GA to assume this role on a branches tagged with `my-tag`
    "*",                          # allow GA to assume this role on any branch in response to any event (use with caution)
  ]
}
```
