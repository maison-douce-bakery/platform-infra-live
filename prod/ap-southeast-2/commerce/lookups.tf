# Other stacks are found by name and tag, never by remote state.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "this" {
  tags = { Name = "mdb-prod-vpc" }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = { Tier = "public" }
}

data "aws_db_instance" "this" {
  db_instance_identifier = "mdb-prod"
}

data "aws_security_group" "rds" {
  name   = "mdb-prod-rds"
  vpc_id = data.aws_vpc.this.id
}

data "aws_ecs_cluster" "this" {
  cluster_name = "mdb-prod"
}

data "aws_iam_policy" "boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}
