#!/usr/bin/env bash
set -euo pipefail

# Runs once on first cluster init (empty $PGDATA). Replaces the catch-all TCP rule so:
# - Non-SSL TCP is rejected
# - SSL TCP requires SCRAM + a client cert signed by ssl_ca_file (clientcert=verify-ca; CN need not match role)

hba="${PGDATA}/pg_hba.conf"

if [[ ! -f "${hba}" ]]; then
  echo "pg_hba.conf not found at ${hba}" >&2
  exit 1
fi

# Replace Docker's default last line: host all all all scram-sha-256
if grep -q '^host all all all scram-sha-256$' "${hba}"; then
  sed -i 's/^host all all all scram-sha-256$/hostnossl all all all reject\nhostssl all all all scram-sha-256 clientcert=verify-ca/' "${hba}"
else
  echo "Expected default scram-sha-256 host rule not found; append rules manually." >&2
  printf '\nhostnossl all all all reject\nhostssl all all all scram-sha-256 clientcert=verify-ca\n' >>"${hba}"
fi
