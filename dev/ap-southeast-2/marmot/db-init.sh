# Runs in the db-init container (sh -ec). Idempotent, so every run converges to the same state.
# The password comes from the environment and is never echoed.
psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
\getenv pw MARMOT_PASSWORD
SELECT 'CREATE ROLE marmot LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'marmot')\gexec
SELECT format('ALTER ROLE marmot WITH LOGIN PASSWORD %L', :'pw')\gexec
-- PostgreSQL 16+: the creator may only make marmot a database owner after taking SET on it.
GRANT marmot TO CURRENT_USER WITH SET TRUE;
SELECT 'CREATE DATABASE marmot OWNER marmot' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'marmot')\gexec
REVOKE ALL ON DATABASE marmot FROM PUBLIC;
SQL
echo "role and database marmot are ready"
