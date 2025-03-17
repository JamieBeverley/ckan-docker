#!/usr/bin/env bash

ROOT="$(dirname ${BASH_SOURCE[0]})/.."

export CKAN_API_KEY=`docker compose -f "${ROOT}/docker-compose.dev.yml" exec ckan-dev ckan user token add ckan_admin TOKEN_NAME=test | awk 'NR==2 {print $1}'`
