#!/bin/bash

# Start PostgreSQL service
runuser -l postgres -c '/etc/init.d/postgresql start'

# Execute CMD
exec "$@"
