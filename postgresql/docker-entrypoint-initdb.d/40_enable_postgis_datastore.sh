#!/bin/bash
set -e

psql --username "$POSTGRES_USER" -d "$DATASTORE_DB" -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# Grant access to spatial_ref_sys table to datastore write user
# TODO what specific privileges are required? can this just be SELECT?
psql --username "$POSTGRES_USER" -d "$DATASTORE_DB"  <<-EOSQL
    GRANT ALL PRIVILEGES ON spatial_ref_sys TO "$CKAN_DB_USER";
EOSQL
