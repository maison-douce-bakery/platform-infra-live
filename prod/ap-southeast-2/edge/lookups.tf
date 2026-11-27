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

data "aws_acm_certificate" "this" {
  domain      = local.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "this" {
  name         = local.zone_name
  private_zone = false
}
