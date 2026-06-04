FROM postgres:18.4

# Update the package list and install the extensions in a single layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       postgresql-18-postgis-3 \
       postgresql-18-postgis-3-scripts \
       postgresql-18-pgvector \
       postgresql-18-pgrouting \
    && rm -rf /var/lib/apt/lists/*