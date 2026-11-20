module "rds" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/rds-postgres?ref=rds-postgres/v0.1.0"

  name           = "mdb-dev"
  vpc_id         = data.aws_vpc.this.id
  subnet_ids     = data.aws_subnets.database.ids
  instance_class = "db.t4g.micro"

  # Dev runs single-AZ: an AZ outage pausing dev is acceptable, a standby would double the cost.
  multi_az = false
}
