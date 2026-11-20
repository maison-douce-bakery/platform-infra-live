# The ECS agent on the host pulls the image and reads the secrets, so the task itself only talks to RDS.
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

resource "aws_vpc_security_group_ingress_rule" "rds_from_db_init" {
  security_group_id            = data.aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.db_init.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "${local.name} db-init"
}
