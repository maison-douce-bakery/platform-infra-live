locals {
  name              = "mdb-prod-data-platform"
  capacity_provider = "FARGATE"

  # The image is the upstream Dagu image plus the data tools, and still runs as uid/gid 1000 (user dagu).
  dagu_uid = 1000

  dagu_image = "452258152479.dkr.ecr.ap-southeast-2.amazonaws.com/mdb/dagu-dbt@sha256:5843d84dfd3179aa9a1980100d1789448130edfa4ee5c25a41d906d19751408a"

  # The role owns the schemas staging, intermediate, marts and snapshots and can only read the application's schema.
  dbt_role = "dbt"

  # Bump after changing the dbt-password parameter to rerun db-init.
  dbt_password_version = 1

  ssm_prefix = "/mdb/prod/data-platform"

  # The role owns the schema raw, where the loader writes, and nothing else.
  dp_loader_role = "dp_loader"

  # Bump after changing the dp-loader-password parameter to rerun db-init.
  dp_loader_password_version = 1

  # Bump after changing the marmot db-password parameter to rerun db-init.
  marmot_password_version = 1

  marmot_ssm_prefix = "/mdb/prod/marmot"

  # The role can only read the application's schema; the Dagu task uses it to register Marmot's PostgreSQL source.
  marmot_reader_role = "marmot_reader"

  # Bump after changing the marmot reader-password parameter to rerun db-init.
  marmot_reader_password_version = 1

  # Created by hand with the CLI, never read by Terraform.
  dbt_password_arn           = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/dbt-password"
  dp_loader_password_arn     = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/dp-loader-password"
  marmot_password_arn        = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.marmot_ssm_prefix}/db-password"
  marmot_reader_password_arn = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.marmot_ssm_prefix}/reader-password"
  marmot_admin_password_arn  = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.marmot_ssm_prefix}/admin-password"
  gitsync_token_arn          = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/gitsync-token"

  # The bucket comes from the datalake stack; the function is deployed by its own repo.
  datalake_bucket_name = "mdb-prod-datalake-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  ingest_function_name = "mdb-prod-ingest-open-meteo"

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
