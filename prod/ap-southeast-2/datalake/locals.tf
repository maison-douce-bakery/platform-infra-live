locals {
  bucket_name = "mdb-prod-datalake-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
