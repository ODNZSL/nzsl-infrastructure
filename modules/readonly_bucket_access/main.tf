
resource "aws_iam_user" "access" {
  name = var.user_name
  tags = var.default_tags
}

resource "aws_iam_access_key" "access" {
  user = aws_iam_user.access.name
}

resource "aws_iam_policy" "access" {
  name        = "${var.user_name}_readonly_bucket_access_policy"
  description = "Allows read-only access to the S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "${var.user_name}ReadonlyBucketAccess",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "access" {
  user       = aws_iam_user.access.name
  policy_arn = aws_iam_policy.access.arn
}
