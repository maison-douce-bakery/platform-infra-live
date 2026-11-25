# Runs in the db-init container (sh -ec). Idempotent, so every run converges to the same state.
# The password comes from the environment and is never echoed. The application creates its own
# schema inside this database on first start, as the owner.
psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
\getenv pw COMMERCE_PASSWORD
SELECT 'CREATE ROLE commerce LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'commerce')\gexec
SELECT format('ALTER ROLE commerce WITH LOGIN PASSWORD %L', :'pw')\gexec
-- PostgreSQL 16+: the creator may only make commerce a database owner after taking SET on it.
GRANT commerce TO CURRENT_USER WITH SET TRUE;
SELECT 'CREATE DATABASE bakery OWNER commerce' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bakery')\gexec
REVOKE ALL ON DATABASE bakery FROM PUBLIC;
SQL
echo "role commerce and database bakery are ready"
