locals {
  # One certificate per hostname, so adding a host never replaces an existing certificate.
  domain_names = toset(["dagu.datawithme.qd.je", "marmot.datawithme.qd.je"])

  # The public zone is owned by platform-aws-foundation (dns/).
  zone_name = "datawithme.qd.je"
}
