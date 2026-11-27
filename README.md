# platform-infra-live

Live AWS infrastructure, one Terraform state per stack, laid out as `<env>/<region>/<stack>/`.

| Stack | Creates |
|---|---|
| `prod/ap-southeast-2/network` | VPC `10.10.0.0/16` from the `vpc` module: public, private and database subnets, no NAT gateway |
| `prod/ap-southeast-2/rds` | PostgreSQL 18 `mdb-prod` (`db.t4g.micro`, single-AZ) in the database subnets, from the `rds-postgres` module |
| `prod/ap-southeast-2/ecs` | Fargate ECS cluster `mdb-prod` with the FARGATE and FARGATE_SPOT capacity providers, from the `ecs-cluster` module |
| `prod/ap-southeast-2/commerce` | Database `bakery` and role `commerce` on `mdb-prod` for the `commerce-api` application, its login in Secrets Manager, created by a `db-init` task |
| `prod/ap-southeast-2/datalake` | S3 bucket `mdb-prod-datalake-<account>-<region>` for raw data: versioned, encrypted, private, never destroyed by Terraform |
| `prod/ap-southeast-2/ingest-open-meteo` | Lambda (arm64 container image from ECR `mdb/ingest-open-meteo`, pinned by digest) that lands Open-Meteo raw files under `raw/open_meteo/` in the datalake bucket. No schedule: Dagu invokes it. Needs the `datalake` stack |
| `prod/ap-southeast-2/certificate` | ACM certificates for `dagu.datawithme.qd.je` and `marmot.datawithme.qd.je`, validated by DNS in the Route 53 zone `datawithme.qd.je`. Never destroyed |
| `prod/ap-southeast-2/edge` | Public Application Load Balancer `mdb-prod-edge` (HTTPS on 443, HTTP redirects) with the target groups `mdb-prod-dagu` and `mdb-prod-marmot`, a host rule for `marmot.datawithme.qd.je` and the DNS records `dagu.datawithme.qd.je` and `marmot.datawithme.qd.je`. Needs the `certificate` stack |
| `prod/ap-southeast-2/data-platform` | Dagu as a Fargate task (public subnet, no inbound, ECS Exec) with its state on an encrypted, backed-up EFS file system, from the `ecs-service` module. DAGs come from `data-orchestration` through Git Sync; the `dbt` and `dp_loader` database users, the read-only `marmot_reader` user and schema `raw` are created here, their passwords live in SSM Parameter Store (set by hand). The task role can invoke the ingest Lambda and read `raw/open_meteo/` in the datalake bucket. Needs the database `bakery` and the `datalake` stack |
| `prod/ap-southeast-2/marmot` | Marmot data catalog as a Fargate task (public subnet, reached through the edge stack's ALB, ECS Exec) from the `ecs-service` module, with its state in the database `marmot` on RDS. The database password and encryption key live in SSM Parameter Store (set by hand); the role and database come from `data-platform`. Needs the `edge` and `data-platform` stacks |

## Making a change

Merging to `main` deploys. Nobody applies from a laptop.

1. Create a branch and edit the stack.
2. Open a PR. CI runs static checks on every stack and a read-only `plan` for the stacks you changed. Read the plan summary.
3. Merge with rebase. CI applies only the changed stacks on `main` through the `prod` environment, which only `main` can use. A change under `.github/`, to `backend.hcl` or to `.tflint.hcl` counts as a change to every stack.

To check for drift while prod is up, run the workflow manually: it plans every stack and the plan fails if live AWS no longer matches `main`.

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
