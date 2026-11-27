locals {
  name        = "mdb-prod-edge"
  domain_name = "dagu.datawithme.qd.je"
  zone_name   = "datawithme.qd.je"

  # The Dagu task listens on this port; its security group belongs to data-platform.
  dagu_port = 8080
}
