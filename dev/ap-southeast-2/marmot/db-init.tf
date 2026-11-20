# One-off task that creates the role and database marmot with the RDS master login.
resource "aws_cloudwatch_log_group" "db_init" {
  name              = "/ecs/${local.name}-db-init"
  retention_in_days = 30
}

resource "aws_iam_role" "db_init_execution" {
  name                 = "${local.name}-db-init-execution"
  path                 = "/workload/"
  permissions_boundary = data.aws_iam_policy.boundary.arn
  assume_role_policy   = local.ecs_tasks_assume_role_policy
}

resource "aws_iam_role_policy_attachment" "db_init_execution" {
  role       = aws_iam_role.db_init_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "db_init_secrets" {
  name = "read-secrets"
  role = aws_iam_role.db_init_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [data.aws_db_instance.this.master_user_secret[0].secret_arn, aws_secretsmanager_secret.db.arn]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = [data.aws_db_instance.this.master_user_secret[0].kms_key_id, aws_kms_key.this.arn]
      },
    ]
  })
}

resource "aws_ecs_task_definition" "db_init" {
  family                   = "${local.name}-db-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 256
  execution_role_arn       = aws_iam_role.db_init_execution.arn

  container_definitions = jsonencode([{
    name       = "db-init"
    image      = local.psql_image
    essential  = true
    entryPoint = ["sh", "-ec"]
    command    = [file("${path.module}/db-init.sh")]
    environment = [
      { name = "PGHOST", value = data.aws_db_instance.this.address },
      { name = "PGPORT", value = tostring(data.aws_db_instance.this.port) },
      { name = "PGDATABASE", value = "postgres" },
      { name = "PGSSLMODE", value = "require" },
      { name = "PGCONNECT_TIMEOUT", value = "10" },
    ]
    secrets = [
      { name = "PGUSER", valueFrom = "${data.aws_db_instance.this.master_user_secret[0].secret_arn}:username::" },
      { name = "PGPASSWORD", valueFrom = "${data.aws_db_instance.this.master_user_secret[0].secret_arn}:password::" },
      { name = "MARMOT_PASSWORD", valueFrom = "${aws_secretsmanager_secret.db.arn}:password::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.db_init.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "db-init"
      }
    }
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

# Runs the task on create and again when the task, the DB instance or the password changes.
resource "terraform_data" "db_init" {
  triggers_replace = [
    aws_ecs_task_definition.db_init.arn,
    data.aws_db_instance.this.resource_id,
    local.db_password_version,
  ]

  provisioner "local-exec" {
    interpreter = ["bash"]
    command     = "${path.module}/run-task.sh"
    environment = {
      REGION            = data.aws_region.current.region
      CLUSTER           = data.aws_ecs_cluster.this.cluster_name
      TASK_DEFINITION   = aws_ecs_task_definition.db_init.arn
      CAPACITY_PROVIDER = local.capacity_provider
      SUBNETS           = join(",", data.aws_subnets.private.ids)
      SECURITY_GROUP    = aws_security_group.db_init.id
    }
  }

  depends_on = [
    aws_secretsmanager_secret_version.db,
    aws_iam_role_policy.db_init_secrets,
    aws_iam_role_policy_attachment.db_init_execution,
    aws_vpc_security_group_egress_rule.db_init_to_rds,
    aws_vpc_security_group_ingress_rule.rds_from_db_init,
  ]
}
