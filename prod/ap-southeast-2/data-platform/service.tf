module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.5.0"

  name                   = local.name
  cluster_name           = data.aws_ecs_cluster.this.cluster_name
  capacity_provider_name = "FARGATE"
  vpc_id                 = data.aws_vpc.this.id
  subnet_ids             = data.aws_subnets.public.ids

  # No NAT: the task gets a public IPv4 to pull its image and reach AWS. No inbound rule exists.
  assign_public_ip = true

  image = local.dagu_image

  # No listener: admins reach the UI on localhost:8080 inside the task with SSM port forwarding through ECS Exec.
  container_port         = null
  enable_execute_command = true

  # Steps run inside this container for now.
  cpu    = 256
  memory = 1024

  environment = {
    DAGU_HOME = "/var/lib/dagu"
    DAGU_HOST = "0.0.0.0"
    DAGU_PORT = "8080"
    TZ        = "Asia/Ho_Chi_Minh"

    DAGU_SKIP_EXAMPLES = "true"

    # Pull-only Git Sync, like Airflow's git-sync: the repository is the source of the DAGs.
    DAGU_GITSYNC_ENABLED           = "true"
    DAGU_GITSYNC_REPOSITORY        = "https://github.com/maison-douce-bakery/data-orchestration.git"
    DAGU_GITSYNC_BRANCH            = "main"
    DAGU_GITSYNC_PATH              = "dags"
    DAGU_GITSYNC_PUSH_ENABLED      = "false"
    DAGU_GITSYNC_AUTOSYNC_ENABLED  = "true"
    DAGU_GITSYNC_AUTOSYNC_INTERVAL = "60"

    DBT_HOST   = data.aws_db_instance.this.address
    DBT_PORT   = tostring(data.aws_db_instance.this.port)
    DBT_USER   = local.dbt_role
    DBT_DBNAME = "bakery"

    DP_LOADER_HOST   = data.aws_db_instance.this.address
    DP_LOADER_PORT   = tostring(data.aws_db_instance.this.port)
    DP_LOADER_USER   = local.dp_loader_role
    DP_LOADER_DBNAME = "bakery"

    DATALAKE_BUCKET = data.aws_s3_bucket.datalake.id

    # Dagu hands steps only DAGU_*, DAG_*, LC_* and a short allowlist; this lets the DBT_*, DP_*, DATALAKE_* and AWS_* (task role credentials) env reach the steps.
    DAGU_ENV_PASSTHROUGH_PREFIXES = "DBT_,DP_,DATALAKE_,AWS_"
  }

  ssm_secrets = {
    DBT_PASSWORD       = local.dbt_password_arn
    DP_LOADER_PASSWORD = local.dp_loader_password_arn
    # Created by hand with the CLI, so no value reaches Terraform state; it survives teardown.
    DAGU_GITSYNC_AUTH_TOKEN = local.gitsync_token_arn
  }

  efs_volumes = {
    data = {
      file_system_id  = aws_efs_file_system.this.id
      access_point_id = aws_efs_access_point.this.id
      container_path  = "/var/lib/dagu"
    }
  }

  desired_count = 1

  # Only one Dagu scheduler may run per data directory: stop the old task before starting the new one.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn

  # Steps invoke the ingest Lambda and read its raw files; Dagu can't write to the bucket.
  # s3fs lists the folder itself ("raw/open_meteo") and its content ("raw/open_meteo/..."), never the bucket root.
  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${local.ingest_function_name}"
      },
      {
        # Not limited by s3:prefix: s3fs also calls HeadBucket, which carries no prefix. Objects stay limited to raw/open_meteo/.
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = data.aws_s3_bucket.datalake.arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.datalake.arn}/raw/open_meteo/*"
      },
    ]
  })

  # The NFS rule needs the module's security group, so it can't be listed here; it's created long before a task is up.
  depends_on = [aws_efs_mount_target.this]
}

# Lets Dagu connect to RDS as dbt. Can't be in the module's `depends_on`: it needs the module's
# security group, which would be a cycle.
resource "aws_vpc_security_group_ingress_rule" "rds_from_service" {
  security_group_id            = data.aws_security_group.rds.id
  referenced_security_group_id = module.service.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = local.name
}
