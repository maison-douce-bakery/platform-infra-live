locals {
  name              = "mdb-dev-commerce"
  capacity_provider = "mdb-dev-ec2"

  # The application owns this database and creates its own schema on first start.
  database = "bakery"
  db_role  = "commerce"

  # Bump to rotate. The next apply writes a new password and reruns db-init.
  db_password_version = 1

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
