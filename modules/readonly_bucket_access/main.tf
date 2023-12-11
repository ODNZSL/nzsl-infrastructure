
resource "aws_iam_user" "access" {
  name = var.user_name
  tags = var.default_tags
}

resource "aws_iam_access_key" "access" {
  user = aws_iam_user.access.name
}

resource "aws_s3_bucket_policy" "access" {
  bucket = var.bucket_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "MediaBucket-Access",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
        ],
        "Principal" : {
          "AWS" : "${aws_iam_user.access.arn}"
        },
        "Resource" : [
          "${var.bucket_name}/*",
        ]
      }
    ]
  })
}