module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.4.0"

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

  # The NFS rule needs the module's security group, so it can't be listed here; it's created long before a task is up.
  depends_on = [aws_efs_mount_target.this]
}
