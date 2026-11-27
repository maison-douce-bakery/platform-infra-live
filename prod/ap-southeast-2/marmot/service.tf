module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.6.0"

  name                   = local.name
  cluster_name           = data.aws_ecs_cluster.this.cluster_name
  capacity_provider_name = local.capacity_provider
  vpc_id                 = data.aws_vpc.this.id
  subnet_ids             = data.aws_subnets.public.ids

  # No NAT: the task gets a public IPv4 to pull its image and reach AWS. Inbound is only the ALB on the container port.
  assign_public_ip = true

  image = local.marmot_image

  # The Marmot UI is public through the edge stack's ALB, which is the only source allowed on the port.
  # ECS Exec stays on for SSM port forwarding and shell access.
  container_port                    = 8080
  target_group_arn                  = data.aws_lb_target_group.marmot.arn
  ingress_security_group_ids        = [data.aws_security_group.edge_alb.id]
  health_check_grace_period_seconds = 120
  enable_execute_command            = true

  cpu    = 1024
  memory = 2048

  environment = {
    MARMOT_DATABASE_HOST     = data.aws_db_instance.this.address
    MARMOT_DATABASE_PORT     = tostring(data.aws_db_instance.this.port)
    MARMOT_DATABASE_NAME     = "marmot"
    MARMOT_DATABASE_USER     = "marmot"
    MARMOT_DATABASE_SSLMODE  = "require"
    MARMOT_TELEMETRY_ENABLED = "false"
  }

  ssm_secrets = {
    MARMOT_DATABASE_PASSWORD     = local.db_password_arn
    MARMOT_SERVER_ENCRYPTION_KEY = local.encryption_key_arn
  }

  desired_count = 1

  # Marmot runs one task at a time: stop the old task before starting the new one.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn
}

# Lets Marmot connect to RDS as marmot. Can't be in the module's `depends_on`: it needs the module's
# security group, which would be a cycle.
resource "aws_vpc_security_group_ingress_rule" "rds_from_service" {
  security_group_id            = data.aws_security_group.rds.id
  referenced_security_group_id = module.service.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = local.name
}
