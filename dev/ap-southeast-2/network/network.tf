module "vpc" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/vpc?ref=vpc/v0.2.0"

  name       = "mdb-dev"
  cidr_block = "10.10.0.0/16"
  nat_mode   = "single"
}
