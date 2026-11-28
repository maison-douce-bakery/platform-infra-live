module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.6.0"

  name                   = local.name
  cluster_name           = data.aws_ecs_cluster.this.cluster_name
  capacity_provider_name = local.capacity_provider
  vpc_id                 = data.aws_vpc.this.id
  subnet_ids             = data.aws_subnets.public.ids

  # No NAT: the task gets a public IPv4 to pull its image and reach AWS. Inbound is only the ALB on the container port.
  assign_public_ip = true

  image = local.cube_image

  # No load balancer: callers inside the VPC are allowed on the port by their own security groups.
  # ECS Exec stays on for SSM port forwarding and shell access.
  container_port         = 4000
  enable_execute_command = true

  cpu    = 512
  memory = 2048

  environment = {
    CUBEJS_DB_TYPE = "postgres"
    CUBEJS_DB_HOST = data.aws_db_instance.this.address
    CUBEJS_DB_PORT = tostring(data.aws_db_instance.this.port)
    CUBEJS_DB_NAME = "bakery"
    CUBEJS_DB_USER = "cube_ro"
    # RDS requires TLS; like sslmode=require elsewhere, Cube does not verify the certificate by default.
    CUBEJS_DB_SSL = "true"
    # Production mode: the API requires a JWT signed with CUBEJS_API_SECRET.
    CUBEJS_DEV_MODE = "false"
    # No Cube Store yet: the default in production is the Cube Store driver.
    CUBEJS_CACHE_AND_QUEUE_DRIVER = "memory"
    CUBEJS_TELEMETRY              = "false"
  }

  ssm_secrets = {
    CUBEJS_DB_PASS    = local.db_password_arn
    CUBEJS_API_SECRET = local.api_secret_arn
  }

  desired_count = 1

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn
}

# Lets Cube connect to RDS as cube_ro. Can't be in the module's `depends_on`: it needs the module's
# security group, which would be a cycle.
resource "aws_vpc_security_group_ingress_rule" "rds_from_service" {
  security_group_id            = data.aws_security_group.rds.id
  referenced_security_group_id = module.service.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = local.name
}
