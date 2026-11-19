# Other stacks are found by name and tag, never by remote state.
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

data "aws_iam_policy" "boundary" {
  name        = "mdb-shared-workload-boundary"
  path_prefix = "/platform/"
}
