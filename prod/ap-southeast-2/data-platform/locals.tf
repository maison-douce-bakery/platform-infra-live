locals {
  name              = "mdb-prod-data-platform"
  capacity_provider = "FARGATE"

  # The image is the upstream Dagu image plus the data tools, and still runs as uid/gid 1000 (user dagu).
  dagu_uid = 1000

  dagu_image = "452258152479.dkr.ecr.ap-southeast-2.amazonaws.com/mdb/dagu-dbt@sha256:81ec1df1241e99dc68ea32b1c3b2ba07621ed21e0b78841fa6e33c2bc4e44044"

  # The role owns the schemas staging, intermediate and marts and can only read the application's schema.
  dbt_role = "dbt"

  # Bump after changing the dbt-password parameter to rerun db-init.
  dbt_password_version = 1

  ssm_prefix = "/mdb/prod/data-platform"

  # Created by hand with the CLI, survives teardown, never read by Terraform.
  dbt_password_arn  = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/dbt-password"
  gitsync_token_arn = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/gitsync-token"

  # ECR Public mirror of the Docker official image, same digest (18.7-alpine).
  psql_image = "public.ecr.aws/docker/library/postgres:18.7-alpine@sha256:ff64c9e3bdf8e2120107d3559de8db314e8305f7e38c5105903c6295876738ff"

  # Only ECS in this account may assume the roles (confused deputy protection).
  ecs_tasks_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}
