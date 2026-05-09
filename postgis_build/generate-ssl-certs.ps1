$ErrorActionPreference = "Stop"

# Generates a small CA, server cert, and one shared client cert
# Output: postgis_ssl/ssl/{server-ca.pem,server-ca-key.pem,server-cert.pem,server-key.pem,client-cert.pem,client-key.pem,client.p12}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$Out = Join-Path $Root "postgis_ssl\ssl"

$Days = if ($env:CERT_DAYS) { $env:CERT_DAYS } else { "3650" }

if (-not (Get-Command "openssl" -ErrorAction SilentlyContinue)) {
    throw @"
OpenSSL was not found on PATH.
Install it first, then restart your terminal.

Windows quick install:
  winget install --id ShiningLight.OpenSSL.Light -e
"@
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null
Push-Location $Out

try {
    openssl req -new -x509 -days $Days -nodes `
        -out "server-ca.pem" -keyout "server-ca-key.pem" `
        -subj "/CN=local-postgis-ca/O=local"

    openssl req -new -nodes `
        -out "server.csr" -keyout "server-key.pem" `
        -subj "/CN=local_postgis/O=local"

    @"
subjectAltName=DNS:localhost,DNS:local_postgis,IP:127.0.0.1
"@ | Set-Content -NoNewline -Encoding ascii "server-ext.cnf"

    openssl x509 -req -in "server.csr" -days $Days `
        -CA "server-ca.pem" -CAkey "server-ca-key.pem" -CAcreateserial `
        -out "server-cert.pem" -copy_extensions none `
        -extfile "server-ext.cnf"

    openssl req -new -nodes `
        -out "client.csr" -keyout "client-key.pem" `
        -subj "/CN=composes-shared-client/O=local"

    openssl x509 -req -in "client.csr" -days $Days `
        -CA "server-ca.pem" -CAkey "server-ca-key.pem" -CAcreateserial `
        -out "client-cert.pem"

    Remove-Item -Force "server.csr","client.csr","server-ext.cnf" -ErrorAction SilentlyContinue
    Remove-Item -Force *.srl -ErrorAction SilentlyContinue

    # chmod equivalent isn't meaningful on Windows; keep files as-generated.
    # Optional hardening can be done with icacls if needed.

    openssl pkcs12 -export -out "client.p12" `
        -inkey "client-key.pem" -in "client-cert.pem" -certfile "server-ca.pem" `
        -passout "pass:" -name "composes-client"

    Write-Host "Wrote certs under $Out"
    Write-Host "Connection: same client-cert.pem for any user; supply that user's password (e.g. PGPASSWORD)."
    Write-Host "psql: sslmode=verify-full sslrootcert=server-ca.pem sslcert=client-cert.pem sslkey=client-key.pem"
}
finally {
    Pop-Location
}