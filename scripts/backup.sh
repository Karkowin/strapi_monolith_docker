#!/bin/bash

if [ ! -d "/strapi/dump" ]; then
    mkdir /strapi/dump
fi
runuser -l postgres -c "pg_dump -d $POSTGRES_DB" > /strapi/dump/strapi_$(date +"%Y%m%d%H%M%S").sql