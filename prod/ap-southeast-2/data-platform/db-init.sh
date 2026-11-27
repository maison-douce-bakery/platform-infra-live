# Runs in the db-init container (sh -ec). Idempotent, so every run converges to the same state.
# The password comes from the environment and is never echoed. Database bakery and its schema
# bakery belong to role commerce and are created by the commerce stack and the application.
psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
\getenv pw DBT_PASSWORD
SELECT 'CREATE ROLE dbt LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dbt')\gexec
SELECT format('ALTER ROLE dbt WITH LOGIN PASSWORD %L', :'pw')\gexec
\getenv lpw DP_LOADER_PASSWORD
SELECT 'CREATE ROLE dp_loader LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dp_loader')\gexec
SELECT format('ALTER ROLE dp_loader WITH LOGIN PASSWORD %L', :'lpw')\gexec
GRANT dp_loader TO CURRENT_USER WITH SET TRUE;
\getenv mpw MARMOT_PASSWORD
SELECT 'CREATE ROLE marmot LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'marmot')\gexec
SELECT format('ALTER ROLE marmot WITH LOGIN PASSWORD %L', :'mpw')\gexec
-- PostgreSQL 16+: the creator may only make marmot a database owner after taking SET on it.
GRANT marmot TO CURRENT_USER WITH SET TRUE;
SELECT 'CREATE DATABASE marmot OWNER marmot' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'marmot')\gexec
REVOKE ALL ON DATABASE marmot FROM PUBLIC;
-- PostgreSQL 16+: the creator may only make dbt a schema owner after taking SET on it.
GRANT dbt TO CURRENT_USER WITH SET TRUE;
-- The master reaches database bakery, and acts for commerce in it, through membership of commerce.
GRANT commerce TO CURRENT_USER WITH SET TRUE;
GRANT CONNECT ON DATABASE bakery TO dbt;
-- The commerce stack revokes the default TEMP right from PUBLIC; dbt snapshots need temporary tables.
GRANT TEMPORARY ON DATABASE bakery TO dbt;
-- dp_loader gets no other right on the database and none on schema bakery.
GRANT CONNECT, TEMPORARY ON DATABASE bakery TO dp_loader;
\getenv rpw MARMOT_READER_PASSWORD
SELECT 'CREATE ROLE marmot_reader LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'marmot_reader')\gexec
SELECT format('ALTER ROLE marmot_reader WITH LOGIN PASSWORD %L', :'rpw')\gexec
GRANT CONNECT ON DATABASE bakery TO marmot_reader;
-- The Marmot PostgreSQL plugin calls pg_database_size on every database, which needs CONNECT or this role.
GRANT pg_read_all_stats TO marmot_reader;
SQL

# The application creates its schema when it starts, which can be after this task.
export PGDATABASE=bakery
found=""
for _ in $(seq 1 24); do
  found=$(psql -X -At -c "SELECT 1 FROM pg_namespace WHERE nspname = 'bakery'") || found=""
  [ "$found" = "1" ] && break
  sleep 5
done
[ "$found" = "1" ] || { echo "schema bakery did not appear within 2 minutes: has commerce-api started?" >&2; exit 1; }

psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
CREATE SCHEMA IF NOT EXISTS staging AUTHORIZATION dbt;
CREATE SCHEMA IF NOT EXISTS intermediate AUTHORIZATION dbt;
CREATE SCHEMA IF NOT EXISTS marts AUTHORIZATION dbt;
CREATE SCHEMA IF NOT EXISTS snapshots AUTHORIZATION dbt;
-- Read-only on the application's schema, now and for tables added later.
SET ROLE commerce;
GRANT USAGE ON SCHEMA bakery TO dbt;
GRANT SELECT ON ALL TABLES IN SCHEMA bakery TO dbt;
ALTER DEFAULT PRIVILEGES FOR ROLE commerce IN SCHEMA bakery GRANT SELECT ON TABLES TO dbt;
-- marmot_reader gets no other table right: nothing on raw, staging, intermediate or marts, and no TEMP.
GRANT USAGE ON SCHEMA bakery TO marmot_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA bakery TO marmot_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE commerce IN SCHEMA bakery GRANT SELECT ON TABLES TO marmot_reader;
RESET ROLE;
-- The loader owns schema raw; dbt reads it, now and for tables added later.
CREATE SCHEMA IF NOT EXISTS raw AUTHORIZATION dp_loader;
SET ROLE dp_loader;
GRANT USAGE ON SCHEMA raw TO dbt;
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO dbt;
ALTER DEFAULT PRIVILEGES FOR ROLE dp_loader IN SCHEMA raw GRANT SELECT ON TABLES TO dbt;
RESET ROLE;
SQL
echo "roles dbt, dp_loader, marmot and marmot_reader, database marmot, their schemas, dbt's read access to schemas bakery and raw and marmot_reader's read access to schema bakery are ready"
