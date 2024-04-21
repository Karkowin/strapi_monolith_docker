#!/bin/bash

if (($# != 1)) || ((${#1} < 1)); then
    echo "No command provided"
    exit 1
fi

runuser -l node -c "cd /strapi/$STRAPI_APP_NAME && $1"
