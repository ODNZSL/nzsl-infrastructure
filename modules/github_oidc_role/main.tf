data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  name_full_pascal_case = "${var.name_prefix_pascal_case}GHA"
  oidc_subject_claims   = formatlist("repo:%s/%s:%s", var.github_org_name, var.github_repo_name, var.allowed_oidc_subject_claims)
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_subject_claims
    }
  }
}

resource "aws_iam_role" "main" {
  name = "${local.name_full_pascal_case}Role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${local.name_full_pascal_case}Role"
  }
}

resource "aws_iam_role_policy" "main" {
  count = length(var.iam_policy_document_json) > 0 ? 1 : 0

  name = local.name_full_pascal_case
  role = aws_iam_role.main.id

  policy = var.iam_policy_document_json
}
