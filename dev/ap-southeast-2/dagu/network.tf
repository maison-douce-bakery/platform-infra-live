resource "aws_security_group" "efs" {
  name        = "${local.name}-efs"
  description = "EFS mount targets of ${local.name}"
  vpc_id      = data.aws_vpc.this.id

  tags = { Name = "${local.name}-efs" }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_service" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = module.service.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "NFS from ${local.name}"
}
