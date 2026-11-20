resource "aws_kms_key" "this" {
  description             = "Secrets of ${local.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.this.key_id
}

# Values are generated at apply time and written write-only: never in plan or state.
ephemeral "random_password" "db" {
  length = 32
  # URL-safe, in case the password ends up in a connection URL.
  override_special = "-_"
}

ephemeral "random_bytes" "encryption_key" {
  length = 32
}

resource "aws_secretsmanager_secret" "db" {
  name        = "mdb-dev/marmot/db"
  description = "PostgreSQL login of Marmot"
  kms_key_id  = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string_wo = jsonencode({
    username = "marmot"
    password = ephemeral.random_password.db.result
  })
  secret_string_wo_version = local.db_password_version
}

# Marmot encrypts stored pipeline credentials with it (base64 of 32 bytes, like `marmot generate-encryption-key`).
resource "aws_secretsmanager_secret" "encryption_key" {
  name        = "mdb-dev/marmot/encryption-key"
  description = "Encryption key for credentials stored by Marmot"
  kms_key_id  = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "encryption_key" {
  secret_id                = aws_secretsmanager_secret.encryption_key.id
  secret_string_wo         = ephemeral.random_bytes.encryption_key.base64
  secret_string_wo_version = local.encryption_key_version
}
