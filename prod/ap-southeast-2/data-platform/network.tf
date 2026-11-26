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

# On Fargate the task ENI pulls the image and reads the secrets, so it needs HTTPS out as well as RDS.
resource "aws_security_group" "db_init" {
  name        = "${local.name}-db-init"
  description = "db-init task of ${local.name}"
  vpc_id      = data.aws_vpc.this.id

  tags = { Name = "${local.name}-db-init" }
}

resource "aws_vpc_security_group_egress_rule" "db_init_to_rds" {
  security_group_id            = aws_security_group.db_init.id
  referenced_security_group_id = data.aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL"
}

resource "aws_vpc_security_group_egress_rule" "db_init_https" {
  security_group_id = aws_security_group.db_init.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS to ECR, SSM, Secrets Manager and CloudWatch Logs"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_db_init" {
  security_group_id            = data.aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.db_init.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "${local.name} db-init"
}
