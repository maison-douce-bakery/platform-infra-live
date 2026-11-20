# platform-infra-live

Live AWS infrastructure, one Terraform state per stack, laid out as `<env>/<region>/<stack>/`.

| Stack | Creates |
|---|---|
| `dev/ap-southeast-2/network` | VPC `10.10.0.0/16` from the `vpc` module: public, private and database subnets, one NAT gateway |
| `dev/ap-southeast-2/rds` | PostgreSQL 18 `mdb-dev` (`db.t4g.micro`, single-AZ) in the database subnets, from the `rds-postgres` module |
| `dev/ap-southeast-2/ecs` | ECS cluster `mdb-dev` with 0-2 `t4g.small` instances scaled by a capacity provider, in the private subnets, from the `ecs-cluster` module |

## Making a change

Merging to `main` deploys. Nobody applies from a laptop.

1. Create a branch and edit the stack.
2. Open a PR. CI runs static checks and a read-only `plan` per stack. Read the plan summary.
3. Merge with rebase. CI applies on `main` through the `dev` environment, which only `main` can use.

To check for drift while dev is up, run the workflow manually: the plan fails if live AWS no longer matches `main`.

To plan locally with an admin session:

```bash
cd dev/ap-southeast-2/network
terraform init -backend-config=../../../backend.hcl
terraform plan
```

## Adding a stack

Create `<env>/<region>/<stack>/` with a `backend.tf` that sets only `key`
(`platform-infra-live/<env>/<region>/<stack>/terraform.tfstate`). The rest of the backend comes from
`backend.hcl`. Add the stack to the workflow and its plan check to `platform-github`.
