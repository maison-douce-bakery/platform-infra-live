locals {
  name              = "mdb-prod-cube"
  capacity_provider = "FARGATE"

  cube_image = "452258152479.dkr.ecr.ap-southeast-2.amazonaws.com/mdb/cube@sha256:890059b05885360870cb39b847979218a794e3e716e4564413da51daa69b9ea9"

  ssm_prefix = "/mdb/prod/cube"

  # Created by hand with the CLI, never read by Terraform. The role cube_ro comes from the data-platform stack.
  db_password_arn = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/db-password"
  api_secret_arn  = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/api-secret"
}
