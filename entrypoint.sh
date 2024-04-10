#!/bin/bash

# Get environment variables
source /etc/environment

# Start PostgreSQL service as user postgres
/etc/init.d/postgresql start

# Check if the $POSTGRES_USER exists; if not, create it
if [ -z "$(runuser -l postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'\"")" ]; then
    runuser -l postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\""
# Else, output the user already exists
else
    echo "User $POSTGRES_USER already exists"
fi

# Check if the $POSTGRES_DB exists; if not, create it
if [ -z "$(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -w $POSTGRES_DB")" ]; then
    runuser -l postgres -c "psql -c \"CREATE DATABASE $POSTGRES_DB WITH OWNER $POSTGRES_USER;\""
# Else, output the database already exists
else
    echo "Database $POSTGRES_DB already exists"
fi

# Check if the /strapi directory is empty if not, creat porject using the $STRAPI_APP_NAME environment variable
if [ -z "$(ls -A /strapi)" ]; then
    runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --dbforce"
# Else, output the directory is not empty
else
    echo "/strapi directory is not empty"
fi

# Start Strapi service as user node
runuser -l node -c "cd /strapi/$STRAPI_APP_NAME && npm run develop"