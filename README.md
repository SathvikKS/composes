# Docker Compose Services

This repository contains Docker Compose configuration files for various development services. Each service can be run independently using its respective YAML file.

## Prerequisites

- [Docker](https://www.docker.com/get-started) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) installed (or Docker Desktop which includes Compose)

## Available Services

### 1. PostgreSQL (with PostGIS)
**File:** `postgres.yml`

PostgreSQL database with PostGIS extension for geospatial data.

**Start:**
```bash
docker compose -f postgres.yml up -d
```

**Connection Details:**
- Host: `localhost`
- Port: `5432`
- Username: `postgres`
- Password: `postgres`
- Database: `postgres`

**Stop:**
```bash
docker compose -f postgres.yml down
```

---

### 2. Redis
**File:** `redis.yml`

Redis in-memory data store.

**Start:**
```bash
docker compose -f redis.yml up -d
```

**Connection Details:**
- Host: `localhost`
- Port: `6379`
- Password: `redis_password`

**Stop:**
```bash
docker compose -f redis.yml down
```

---

### 3. MongoDB
**File:** `mongodb.yml`

MongoDB NoSQL database.

**Start:**
```bash
docker compose -f mongodb.yml up -d
```

**Connection Details:**
- Host: `localhost`
- Port: `27017`
- Username: `admin`
- Password: `admin`
- Database: `admin`

**Connection String:**
```
mongodb://admin:admin@localhost:27017/admin
```

**Stop:**
```bash
docker compose -f mongodb.yml down
```

---

### 4. MySQL
**File:** `mysql.yml`

MySQL relational database.

**Start:**
```bash
docker compose -f mysql.yml up -d
```

**Connection Details:**
- Host: `localhost`
- Port: `3306`
- Username: `root`
- Password: `toor`

**Stop:**
```bash
docker compose -f mysql.yml down
```

---

### 5. MinIO
**File:** `minio.yml`

MinIO object storage service (S3-compatible).

**Start:**
```bash
docker compose -f minio.yml up -d
```

**Access Points:**
- API Endpoint: `http://localhost:9000`
- Console UI: `http://localhost:9090`
- Username: `minio_user`
- Password: `minio_password`

**Stop:**
```bash
docker compose -f minio.yml down
```

---

### 6. Coturn (TURN Server)
**File:** `coturn.yml`

Coturn TURN/STUN server for WebRTC applications.

**Start:**
```bash
docker compose -f coturn.yml up -d
```

**Note:** This service uses `host` network mode. Configuration is managed via `turnserver.conf`.

**Stop:**
```bash
docker compose -f coturn.yml down
```

---

### 7. PostGIS SSL (`postgis_ssl`)

**File:** `postgis-ssl.yml`

PostGIS with **TLS**, **SCRAM (password)**, and a **single shared client certificate**: TCP connections must use SSL, present `client-cert.pem` / `client-key.pem` (signed by `server-ca.pem`), and authenticate the **database role with that role’s password**. One client cert is enough for every username; `pg_hba` uses **`clientcert=verify-ca`**, which checks the cert is issued by the CA but **does not** require the cert’s CN to match the role (unlike `cert` or `clientcert=verify-full`).

This stack uses its **own data directory** (`./postgis_ssl/data`) and **does not** change `postgis.yml` or `postgres.yml`.

#### 1. Generate TLS material first

Certs must exist **before** `up`, because Postgres starts with `ssl=on` and reads files from the mounted `./postgis_ssl/ssl` directory.

From the repo root:

```bash
bash postgis_build/generate-ssl-certs.sh
```

This writes (under `postgis_ssl/ssl/`):

| File | Role |
|------|------|
| `server-cert.pem` / `server-key.pem` | Server TLS (used by Postgres inside the container) |
| `server-ca.pem` / `server-ca-key.pem` | Certificate authority (public cert + private key; only the **`.pem` cert** is referenced by Postgres as `ssl_ca_file`) |
| `client-cert.pem` / `client-key.pem` | **Shared** client TLS identity (same files for any DB user; paired with each user’s password) |
| `client.p12` | Optional PKCS#12 bundle (empty export password) |

Optional: set validity with `CERT_DAYS` (default `3650`).

#### 2. Key permissions (if the container fails to read keys)

The `postgres` process in the image often runs as UID **999**. If bind-mounted keys are owned by your host user, fix ownership or permissions, for example:

```bash
sudo chown 999:999 postgis_ssl/ssl/server-key.pem postgis_ssl/ssl/client-key.pem postgis_ssl/ssl/server-ca-key.pem
chmod 600 postgis_ssl/ssl/*-key.pem postgis_ssl/ssl/server-ca-key.pem
```

#### 3. Start and stop

**Start:**
```bash
docker compose -f postgis-ssl.yml up -d
```

**Stop:**
```bash
docker compose -f postgis-ssl.yml down
```

**Connection (host):**

- Host: `localhost`
- Port: `5433` (maps to `5432` in the container)
- **User / database:** any role you created (e.g. `ringi`, `postgres`) — use that role’s **password**
- TLS: `sslmode=verify-full` with `sslrootcert`, `sslcert`, and `sslkey` (same client PEMs for every user)

**`psql` example** (user `ringi`; set password however you prefer):

```bash
PGPASSWORD='your-ringi-password' psql "host=localhost port=5433 user=ringi dbname=postgres sslmode=verify-full sslrootcert=postgis_ssl/ssl/server-ca.pem sslcert=postgis_ssl/ssl/client-cert.pem sslkey=postgis_ssl/ssl/client-key.pem"
```

GUI clients must enable SSL and attach the same CA + client cert/key; **do not** disable SSL or you will see `pg_hba.conf rejects connection … no encryption`.

#### First-time database init

`postgis_build/initdb-ssl/` is mounted as `/docker-entrypoint-initdb.d` and runs **only when `./postgis_ssl/data` is empty** (first cluster creation). It sets `pg_hba` so non-SSL TCP is rejected and SSL requires **SCRAM + `clientcert=verify-ca`**. If the cluster was created earlier with the old **`cert`**-only rule, Postgres will still show **`certificate authentication failed`** when the DB user does not match the client cert CN. Either:

- Run **`bash postgis_build/upgrade-pg_hba-scram-clientcert.sh`** (container must be up; it edits `pg_hba.conf` inside the container, backs it up, and runs `pg_reload_conf()`), or  
- Manually change line **`hostssl all all all cert`** to **`hostssl all all all scram-sha-256 clientcert=verify-ca`** in `postgis_ssl/data/…/pg_hba.conf` (path matches your PG version, e.g. `18/docker/`), then reload Postgres.

---

## Common Commands

### Start a Service
```bash
docker compose -f <service-name>.yml up -d
```

### Stop a Service
```bash
docker compose -f <service-name>.yml down
```

### View Logs
```bash
docker compose -f <service-name>.yml logs -f
```

### Check Service Status
```bash
docker compose -f <service-name>.yml ps
```

### Restart a Service
```bash
docker compose -f <service-name>.yml restart
```

### Remove Service and Volumes
```bash
docker compose -f <service-name>.yml down -v
```

---

## Data Persistence

All services use volume mounts to persist data:
- PostgreSQL: `./postgres/data`
- PostGIS SSL: `./postgis_ssl/data` (and TLS files in `./postgis_ssl/ssl`)
- Redis: `./redis/data`
- MongoDB: `./mongodb/data`
- MySQL: `./mysql/data`
- MinIO: `./minio/data`

Data is stored locally in these directories and will persist even after stopping containers.

---

## Security Note

⚠️ **Important:** These configurations use default credentials for development purposes only. **Do not use these credentials in production environments.** Change all passwords and credentials before deploying to production.

---

## Troubleshooting

### Port Already in Use
If you get a port conflict error, either:
1. Stop the service using that port
2. Modify the port mapping in the YAML file (e.g., change `"5432:5432"` to `"5433:5432"`)

### Permission Issues
On Linux, you may need to adjust permissions for data directories:
```bash
sudo chown -R $USER:$USER ./postgres/data
```

### View Container Logs
```bash
docker logs <container_name>
```

For example:
```bash
docker logs local_postgres
```
