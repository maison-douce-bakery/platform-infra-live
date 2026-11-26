# Other stacks are found by name, never by remote state.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy" "boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}

data "aws_s3_bucket" "datalake" {
  bucket = local.datalake_bucket_name
}
