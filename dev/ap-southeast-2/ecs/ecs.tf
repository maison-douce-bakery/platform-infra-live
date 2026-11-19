module "ecs_cluster" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/ecs-cluster?ref=ecs-cluster/v0.1.0"

  name       = "mdb-dev"
  vpc_id     = data.aws_vpc.this.id
  subnet_ids = data.aws_subnets.private.ids

  # ECS-optimized AL2023 arm64 (al2023-ami-ecs-hvm-2023.0.20261113). Bump by PR from
  # /aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id.
  ami_id = "ami-08246d4dc9f74f0b7"

  permissions_boundary_arn = data.aws_iam_policy.boundary.arn
}
