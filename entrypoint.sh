#!/bin/bash

# Add /usr/local/bin to PATH if it's not already there
export PATH="/usr/local/bin:$PATH"

# Get environment variables
source /etc/environment

# Start PostgreSQL service as user postgres
/etc/init.d/postgresql start

# Ensure that POSTGRES_USER and POSTGRES_DB are set and follow must start with a lowercase letter or an underscore and only contain lowercase letters, numbers, and underscores (equal to or less than 30 characters)
if [[ ! "$POSTGRES_USER" =~ ^[a-z_][a-z0-9_]{0,29}$ ]]; then
    echo "POSTGRES_USER must start with a lowercase letter or an underscore and only contain lowercase letters, numbers, and underscores (equal to or less than 30 characters)"
    exit 1
fi
if [[ ! "$POSTGRES_DB" =~ ^[a-z_][a-z0-9_]{0,29}$ ]]; then
    echo "POSTGRES_DB must start with a lowercase letter or an underscore and only contain lowercase letters, numbers, and underscores (equal to or less than 30 characters)"
    exit 1
fi

# Ensure that POSTGRES_PASSWORD, STRAPI_APP_NAME, STRAPI_VERSION, and NODE_ENV are set and does not contain any special characters or spaces except for STRAPI_VERSION which can contain dots
if [[ ! "$POSTGRES_PASSWORD" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "POSTGRES_PASSWORD must not contain any special characters or spaces"
    exit 1
fi
if [[ ! "$STRAPI_APP_NAME" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "STRAPI_APP_NAME must not contain any special characters or spaces"
    exit 1
fi
if [[ ! "$STRAPI_VERSION" =~ ^[0-9.]+$ ]]; then
    echo "STRAPI_VERSION must be a valid version number"
    exit 1
fi


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
        runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --example --ts --use-npm --install --no-git-init --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --skip-cloud"
    else
        echo "Project $STRAPI_APP_NAME already exists"
        # Check if the database is empty
        if [ -z "$(runuser -l postgres -c "psql -d $POSTGRES_DB -tAc \"SELECT 1 FROM pg_tables WHERE schemaname = 'public'\"")" ]; then
            echo "Database $POSTGRES_DB is empty"
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
        else
            echo "Database $POSTGRES_DB is not empty"
        fi
    fi
else
    runuser -l node -c "cd /strapi && npx create-strapi-app@$STRAPI_VERSION $STRAPI_APP_NAME --example --ts --use-npm --install --no-git-init --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=$POSTGRES_DB --dbusername=$POSTGRES_USER --dbpassword=$POSTGRES_PASSWORD --dbssl=false --skip-cloud"
fi

# Declare constants depending on the environment
if [ "$NODE_ENV" = "development" ]; then
    RUN_COMMAND="develop"
else
    RUN_COMMAND="build && npm run start"
fi

# Start Strapi service as user node
runuser -l node -c "cd /strapi/$STRAPI_APP_NAME && npm run $RUN_COMMAND"