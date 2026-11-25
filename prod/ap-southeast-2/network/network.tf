module "vpc" {
  source = "git::https://github.com/maison-douce-bakery/platform-terraform-modules.git//modules/vpc?ref=vpc/v0.4.0"

  name       = "mdb-prod"
  cidr_block = "10.10.0.0/16"

  # No NAT: tasks run in public subnets with a public IP, S3 goes through the gateway endpoint.
  nat_mode = "none"
}
