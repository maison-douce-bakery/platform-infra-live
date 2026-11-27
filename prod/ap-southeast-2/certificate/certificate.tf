resource "aws_acm_certificate" "this" {
  for_each = local.domain_names

  domain_name       = each.value
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = merge([
    for cert in aws_acm_certificate.this : {
      for o in cert.domain_validation_options : o.domain_name => o
    }
  ]...)

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  for_each = aws_acm_certificate.this

  certificate_arn         = each.value.arn
  validation_record_fqdns = [for o in each.value.domain_validation_options : aws_route53_record.validation[o.domain_name].fqdn]
}
