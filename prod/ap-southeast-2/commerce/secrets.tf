resource "aws_kms_key" "this" {
  description             = "Secrets of ${local.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.this.key_id
}

# Generated at apply time and written write-only: never in plan or state.
ephemeral "random_password" "db" {
  length = 32
  # URL-safe, in case the password ends up in a connection URL.
  override_special = "-_"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "mdb-prod/commerce/db"
  description = "PostgreSQL login of the commerce application"
  kms_key_id  = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string_wo = jsonencode({
    username = local.db_role
    password = ephemeral.random_password.db.result
  })
  secret_string_wo_version = local.db_password_version
}
