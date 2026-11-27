data "aws_route53_zone" "this" {
  name         = local.zone_name
  private_zone = false
}
