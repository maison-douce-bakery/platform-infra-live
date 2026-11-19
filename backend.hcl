# Shared by every stack: terraform init -backend-config=<path to this file>. Each stack sets only its key.
bucket       = "mdb-shared-tfstate-452258152479-ap-southeast-2-an"
region       = "ap-southeast-2"
encrypt      = true
kms_key_id   = "arn:aws:kms:ap-southeast-2:452258152479:key/ecb785de-52dc-491e-aedf-7933d87850c3"
use_lockfile = true
