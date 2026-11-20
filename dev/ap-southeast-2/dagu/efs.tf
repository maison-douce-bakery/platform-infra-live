# Dagu keeps DAGs, run history, logs and users as files, so they live on EFS, not on an instance disk.
resource "aws_kms_key" "this" {
  description             = "EFS of ${local.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_efs_file_system" "this" {
  encrypted        = true
  kms_key_id       = aws_kms_key.this.arn
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  tags = { Name = local.name }
}

# Daily backups by AWS Backup into aws/efs/automatic-backup-vault.
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(data.aws_subnets.private.ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# Every client lands in /dagu as the dagu user, whatever uid it runs as.
resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = local.dagu_uid
    gid = local.dagu_uid
  }

  root_directory {
    path = "/dagu"

    creation_info {
      owner_uid   = local.dagu_uid
      owner_gid   = local.dagu_uid
      permissions = "0750"
    }
  }

  tags = { Name = local.name }
}

# Only Dagu's task role, only over TLS and only through the access point.
resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyWithoutTls"
        Effect    = "Deny"
        Principal = { AWS = "*" }
        Action    = "*"
        Resource  = aws_efs_file_system.this.arn
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "DaguThroughAccessPoint"
        Effect    = "Allow"
        Principal = { AWS = module.service.task_role_arn }
        Action    = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
        Resource  = aws_efs_file_system.this.arn
        Condition = { StringEquals = { "elasticfilesystem:AccessPointArn" = aws_efs_access_point.this.arn } }
      },
    ]
  })
}
