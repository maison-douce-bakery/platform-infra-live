module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.1.0"

  name                   = local.name
  cluster_name           = data.aws_ecs_cluster.this.cluster_name
  capacity_provider_name = local.capacity_provider
  vpc_id                 = data.aws_vpc.this.id
  subnet_ids             = data.aws_subnets.private.ids

  image          = local.marmot_image
  container_port = 8080

  # A t4g.small registers 1846 MiB; this leaves room for db-init on the same host.
  cpu    = 1024
  memory = 1536

  environment = {
    MARMOT_DATABASE_HOST    = data.aws_db_instance.this.address
    MARMOT_DATABASE_PORT    = tostring(data.aws_db_instance.this.port)
    MARMOT_DATABASE_NAME    = "marmot"
    MARMOT_DATABASE_USER    = "marmot"
    MARMOT_DATABASE_SSLMODE = "require"

    # On by default upstream; no data leaves the company without review.
    MARMOT_TELEMETRY_ENABLED = "false"
  }

  secrets = {
    MARMOT_DATABASE_PASSWORD     = { secret_arn = aws_secretsmanager_secret.db.arn, json_key = "password" }
    MARMOT_SERVER_ENCRYPTION_KEY = { secret_arn = aws_secretsmanager_secret.encryption_key.arn }
  }
  secrets_kms_key_arns = [aws_kms_key.this.arn]

  # No load balancer yet: admins reach the UI with SSM port forwarding through an ECS host.
  ingress_security_group_ids = [data.aws_security_group.ecs_instance.id]

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn

  # Marmot needs its role and database before the first task starts. The RDS rule for this service
  # can't be listed here (it needs the module's security group); it's created long before a task is up.
  depends_on = [
    terraform_data.db_init,
    aws_secretsmanager_secret_version.encryption_key,
  ]
}
