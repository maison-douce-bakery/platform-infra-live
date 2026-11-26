resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 30
}

resource "aws_lambda_function" "this" {
  function_name = local.name
  role          = aws_iam_role.this.arn
  package_type  = "Image"
  image_uri     = local.image_uri
  architectures = ["arm64"]
  memory_size   = 512
  timeout       = 300

  environment {
    variables = {
      DATALAKE_BUCKET = data.aws_s3_bucket.datalake.id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.this.name
  }

  depends_on = [aws_cloudwatch_log_group.this, aws_iam_role_policy.this]
}
