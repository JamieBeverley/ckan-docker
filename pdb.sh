#!/bin/sh

docker attach `docker ps -f name=ckan-docker-ckan-dev --format "{{.ID}}"` 
