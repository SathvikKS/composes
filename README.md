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
