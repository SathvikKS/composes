#!/usr/bin/env bash
# One-time fix for clusters still using "hostssl … cert" (CN must match username).
# Replaces that rule with: scram-sha-256 clientcert=verify-ca (shared client cert + per-user password).
#
# Usage (container running): bash postgis_build/upgrade-pg_hba-scram-clientcert.sh
# Override: POSTGIS_SSL_CONTAINER=myname PG_HBA_IN_CONTAINER=/path/pg_hba.conf

set -euo pipefail

CONTAINER="${POSTGIS_SSL_CONTAINER:-local_postgis_ssl}"
PG_HBA="${PG_HBA_IN_CONTAINER:-/var/lib/postgresql/18/docker/pg_hba.conf}"

docker exec "$CONTAINER" test -f "$PG_HBA"

docker exec "$CONTAINER" bash -c "
set -euo pipefail
hba='${PG_HBA}'
cp -a \"\$hba\" \"\${hba}.bak.$(date +%Y%m%d%H%M%S)\"
if ! grep -qE '^hostssl[[:space:]]+all[[:space:]]+all[[:space:]]+all[[:space:]]+cert[[:space:]]*$' \"\$hba\"; then
  echo 'No line matching \"hostssl all all all cert\" found. Current hostssl rules:' >&2
  grep -n hostssl \"\$hba\" >&2 || true
  exit 1
fi
sed -i -E 's/^hostssl[[:space:]]+all[[:space:]]+all[[:space:]]+all[[:space:]]+cert[[:space:]]*$/hostssl all all all scram-sha-256 clientcert=verify-ca/' \"\$hba\"
echo 'Updated pg_hba.conf (backup beside it in container).'
"

docker exec "$CONTAINER" psql -U postgres -c "SELECT pg_reload_conf();"

echo "Reload issued. Connect as any user with SSL + client cert + that user's password."
