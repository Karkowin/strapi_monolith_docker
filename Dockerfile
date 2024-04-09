# Use the official Node.js 20 image as base
FROM node:20

USER root

# Update packages
RUN apt update && \
    apt upgrade -y

# Install postgres sql
RUN apt install -y postgresql postgresql-contrib

# Declare environment variables for postgres sql
ENV PGDATA=/var/lib/postgresql/data
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=postgres

# Configure postgres sql with user and password and create database
RUN service postgresql start && \
    su - postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';\"" && \
    su - postgres -c "psql -c \"CREATE DATABASE $POSTGRES_DB;\""

# Run the container indefenitely
CMD ["tail", "-f", "/dev/null"]