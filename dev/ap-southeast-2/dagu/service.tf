module "service" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-service?ref=ecs-service/v0.2.0"

  name                   = local.name
  cluster_name           = data.aws_ecs_cluster.this.cluster_name
  capacity_provider_name = local.capacity_provider
  vpc_id                 = data.aws_vpc.this.id
  subnet_ids             = data.aws_subnets.private.ids

  image          = local.dagu_image
  container_port = 8080

  # Steps run inside this container for now, so it gets more than the bare server needs.
  cpu    = 512
  memory = 512

  efs_volumes = {
    data = {
      file_system_id  = aws_efs_file_system.this.id
      access_point_id = aws_efs_access_point.this.id
      container_path  = "/var/lib/dagu"
    }
  }

  # Standalone Dagu allows one process per data directory: stop the old task before starting the new one.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  # No load balancer: admins reach the UI with SSM port forwarding through an ECS host.
  ingress_security_group_ids = [data.aws_security_group.ecs_instance.id]

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn

  # The NFS rule needs the module's security group, so it can't be listed here; it's created long before a task is up.
  depends_on = [aws_efs_mount_target.this]
}
