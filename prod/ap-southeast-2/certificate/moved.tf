moved {
  from = aws_acm_certificate.this
  to   = aws_acm_certificate.this["dagu.datawithme.qd.je"]
}

moved {
  from = aws_acm_certificate_validation.this
  to   = aws_acm_certificate_validation.this["dagu.datawithme.qd.je"]
}
