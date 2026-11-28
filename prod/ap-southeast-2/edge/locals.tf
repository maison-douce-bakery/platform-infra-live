locals {
  name        = "mdb-prod-edge"
  domain_name = "dagu.datawithme.qd.je"
  zone_name   = "datawithme.qd.je"

  marmot_domain_name = "marmot.datawithme.qd.je"

  # Dagu and Marmot tasks listen on this port; their security groups belong to their own stacks.
  target_port = 8080
}
