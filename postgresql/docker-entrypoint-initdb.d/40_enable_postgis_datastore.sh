#!/bin/bash
set -e
set -x
echo "$POSTGRES_USER"
echo "$DATASTORE_DB"

psql --username "$POSTGRES_USER" -d "$DATASTORE_DB" -c "CREATE EXTENSION IF NOT EXISTS postgis;"
