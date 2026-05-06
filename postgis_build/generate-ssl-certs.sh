#!/usr/bin/env bash
# Generates a small CA, server cert, and one shared client cert (any DB user + password; pg_hba uses clientcert=verify-ca).
# Run from repo root: bash postgis_build/generate-ssl-certs.sh
# Output: postgis_ssl/ssl/{server-ca.pem,server-ca-key.pem,server-cert.pem,server-key.pem,client-cert.pem,client-key.pem,client.p12}

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/postgis_ssl/ssl"
DAYS="${CERT_DAYS:-3650}"

mkdir -p "${OUT}"
cd "${OUT}"

openssl req -new -x509 -days "${DAYS}" -nodes -out server-ca.pem -keyout server-ca-key.pem \
  -subj "/CN=local-postgis-ca/O=local"

openssl req -new -nodes -out server.csr -keyout server-key.pem \
  -subj "/CN=local_postgis/O=local"

openssl x509 -req -in server.csr -days "${DAYS}" -CA server-ca.pem -CAkey server-ca-key.pem -CAcreateserial \
  -out server-cert.pem -copy_extensions none \
  -extfile <(printf "subjectAltName=DNS:localhost,DNS:local_postgis,IP:127.0.0.1")

openssl req -new -nodes -out client.csr -keyout client-key.pem \
  -subj "/CN=composes-shared-client/O=local"

openssl x509 -req -in client.csr -days "${DAYS}" -CA server-ca.pem -CAkey server-ca-key.pem -CAcreateserial \
  -out client-cert.pem

rm -f server.csr client.csr ./*.srl

chmod 600 server-key.pem client-key.pem server-ca-key.pem
chmod 644 server-ca.pem server-cert.pem client-cert.pem

openssl pkcs12 -export -out client.p12 -inkey client-key.pem -in client-cert.pem -certfile server-ca.pem \
  -passout pass: -name composes-client

echo "Wrote certs under ${OUT}"
echo "Connection: same client-cert.pem for any user; supply that user's password (e.g. PGPASSWORD)."
echo "psql: sslmode=verify-full sslrootcert=server-ca.pem sslcert=client-cert.pem sslkey=client-key.pem"
