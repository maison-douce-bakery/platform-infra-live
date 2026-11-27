locals {
  name              = "mdb-prod-marmot"
  capacity_provider = "FARGATE"

  marmot_image = "452258152479.dkr.ecr.ap-southeast-2.amazonaws.com/mdb/marmot@sha256:5bfa79ed4dee9d4218d7494a87cd59aab5f00fc1bf37c0534806a0762e18bc7f"

  ssm_prefix = "/mdb/prod/marmot"

  # Created by hand with the CLI, never read by Terraform.
  db_password_arn    = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/db-password"
  encryption_key_arn = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/encryption-key"
}
