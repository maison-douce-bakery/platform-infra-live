resource "aws_iam_role" "this" {
  name                 = local.name
  path                 = "/workload/"
  permissions_boundary = data.aws_iam_policy.boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "ingest"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [aws_cloudwatch_log_group.this.arn, "${aws_cloudwatch_log_group.this.arn}:*"]
      },
      {
        Sid      = "ReadWriteRawPrefix"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${data.aws_s3_bucket.datalake.arn}/raw/open_meteo/*"
      },
      {
        # No prefix condition: the HeadBucket call that s3fs makes carries none.
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = data.aws_s3_bucket.datalake.arn
      },
    ]
  })
}
