# platform-infra-live

Live AWS infrastructure, one Terraform state per stack, laid out as `<env>/<region>/<stack>/`.

| Stack | Creates |
|---|---|
| `prod/ap-southeast-2/network` | VPC `10.10.0.0/16` from the `vpc` module: public, private and database subnets, no NAT gateway |
| `prod/ap-southeast-2/rds` | PostgreSQL 18 `mdb-prod` (`db.t4g.micro`, single-AZ) in the database subnets, from the `rds-postgres` module |
| `prod/ap-southeast-2/ecs` | Fargate ECS cluster `mdb-prod` with the FARGATE and FARGATE_SPOT capacity providers, from the `ecs-cluster` module |
| `prod/ap-southeast-2/commerce` | Database `bakery` and role `commerce` on `mdb-prod` for the `commerce-api` application, its login in Secrets Manager, created by a `db-init` task |
| `prod/ap-southeast-2/datalake` | S3 bucket `mdb-prod-datalake-<account>-<region>` for raw data: versioned, encrypted, private, never destroyed by Terraform |
| `prod/ap-southeast-2/data-platform` | Dagu as a Fargate task (public subnet, no inbound, ECS Exec) with its state on an encrypted, backed-up EFS file system, from the `ecs-service` module. DAGs come from `data-orchestration` through Git Sync; the `dbt` database user is created here, its password lives in SSM Parameter Store (set by hand). Needs the database `bakery` |

## Making a change

Merging to `main` deploys. Nobody applies from a laptop.

1. Create a branch and edit the stack.
2. Open a PR. CI runs static checks and a read-only `plan` per stack. Read the plan summary.
3. Merge with rebase. CI applies on `main` through the `prod` environment, which only `main` can use.

To check for drift while prod is up, run the workflow manually: the plan fails if live AWS no longer matches `main`.

To plan locally with an admin session:

```bash
cd prod/ap-southeast-2/network
terraform init -backend-config=../../../backend.hcl
terraform plan
```

## Adding a stack

Create `<env>/<region>/<stack>/` with a `backend.tf` that sets only `key`
(`platform-infra-live/<env>/<region>/<stack>/terraform.tfstate`). The rest of the backend comes from
`backend.hcl`. Add the stack to the workflow and its plan check to `platform-github`.
