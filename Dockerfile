# Use Node.js version 20 as base image
FROM node:20

# Set environment variables
ENV POSTGRES_USER=changeme \
    POSTGRES_PASSWORD=changeme \
    POSTGRES_DB=changeme \
    STRAPI_APP_NAME=app \
    STRAPI_VERSION=4.23.0

# Install lsb-release
RUN apt-get update \
    && apt-get install -y lsb-release \
    && apt-get clean all

# Add PostgreSQL repository
RUN sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostgreSQL
RUN apt-get update \
    && apt-get install -y postgresql-14 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Install strapi
RUN npm i -g create-strapi-app@$STRAPI_VERSION

# Create working directory and give permissions to node
RUN mkdir -p /strapi && chown -R node:node /strapi
WORKDIR /strapi

# End of Dockerfile
ENTRYPOINT ["entrypoint.sh"]

# npx create-strapi-app@latest app --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=postgres --dbusername=postgres --dbpassword=postgres --dbssl=false --dbforce