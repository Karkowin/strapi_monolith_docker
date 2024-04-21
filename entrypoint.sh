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

# Check if the /strapi directory/$STRAPI_APP_NAME exist and contain file if not, creat project using the $STRAPI_APP_NAME environment variable
if [ -d "/strapi/$STRAPI_APP_NAME" ]; then
    if [ -z "$(ls -A /strapi/$STRAPI_APP_NAME)" ]; then
        echo "Project $STRAPI_APP_NAME exists but is empty"
        rmdir /strapi/$STRAPI_APP_NAME
        runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --dbforce"
    else
        echo "Project $STRAPI_APP_NAME already exists"
        # Check if there is an sql dump file in the /strapi/backup directory
        if [ -n "$(ls -A /strapi/dump/*.sql)" ]; then
            # Restore the database from the most recent dump file
            runuser -l postgres -c "psql -d $POSTGRES_DB -f $(ls -t /strapi/dump/*.sql | head -n1)" > /dev/null
            status=$?
            if [ $status -eq 0 ]; then
                echo "Database restore succeeded"
            else
                echo "Database restore failed"
            fi
        fi
    fi
else
    runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --dbforce"
fi

# Declare constants depending on the environment
if [ "$NODE_ENV" = "development" ]; then
    RUN_COMMAND="develop"
else
    RUN_COMMAND="build && npm run start"
fi

# Start Strapi service as user node
runuser -l node -c "cd /strapi/$STRAPI_APP_NAME && npm run $RUN_COMMAND"