# Other stacks are found by name and tag, never by remote state.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "this" {
  tags = { Name = "mdb-dev-vpc" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = { Tier = "private" }
}

data "aws_db_instance" "this" {
  db_instance_identifier = "mdb-dev"
}

data "aws_security_group" "rds" {
  name   = "mdb-dev-rds"
  vpc_id = data.aws_vpc.this.id
}

data "aws_security_group" "ecs_instance" {
  name   = "mdb-dev-ecs-instance"
  vpc_id = data.aws_vpc.this.id
}

data "aws_ecs_cluster" "this" {
  cluster_name = "mdb-dev"
}

data "aws_iam_policy" "boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}
