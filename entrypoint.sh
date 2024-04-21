#!/bin/bash

# Get environment variables
source /etc/environment

# Start PostgreSQL service as user postgres
/etc/init.d/postgresql start

# Check if the $POSTGRES_USER exists; if not, create it
if [ -z "$(runuser -l postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'\"")" ]; then
    runuser -l postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\""
else
    echo "User $POSTGRES_USER already exists"
fi

# Check if the $POSTGRES_DB exists; if not, create it
if [ -z "$(runuser -l postgres -c "psql -lqt | cut -d \| -f 1 | grep -w $POSTGRES_DB")" ]; then
    runuser -l postgres -c "psql -c \"CREATE DATABASE $POSTGRES_DB WITH OWNER $POSTGRES_USER;\""
else
    echo "Database $POSTGRES_DB already exists"
fi

# Set /strapi directory owner to node
chown -R node:node /strapi

# Check if the /strapi directory/$STRAPI_APP_NAME exist and contain file if not, creat porject using the $STRAPI_APP_NAME environment variable
if [ -d "/strapi/$STRAPI_APP_NAME" ]; then
    echo "$(ls -A /strapi/$STRAPI_APP_NAME)"
    if [ -z "$(ls -A /strapi/$STRAPI_APP_NAME)" ]; then
        echo "Project $STRAPI_APP_NAME exists but is empty"
        rmdir /strapi/$STRAPI_APP_NAME
        runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --dbforce"
    else
        echo "Project $STRAPI_APP_NAME already exists"
    fi
else
    runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --dbforce"
fi

# Declare constants depending on the environment
if [ "$NODE_ENV" = "development" ]; then
    RUN_COMMAND="develop"
else
    RUN_COMMAND="start"
fi

# Start Strapi service as user node
runuser -l node -c "cd /strapi/$STRAPI_APP_NAME && npm run $RUN_COMMAND"