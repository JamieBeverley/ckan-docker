#!/bin/bash
set -e

psql --username "$POSTGRES_USER" -d "$DATASTORE_DB" -c "CREATE EXTENSION IF NOT EXISTS postgis;"
