# Other stacks are found by name and tag, never by remote state.
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

data "aws_ecs_cluster" "this" {
  cluster_name = "mdb-prod"
}

data "aws_iam_policy" "boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}
