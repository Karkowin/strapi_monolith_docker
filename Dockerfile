# Use Node.js version 20 as base image
FROM node:20

# Set environment variables
ENV POSTGRES_USER=changeme \
    POSTGRES_PASSWORD=changeme \
    POSTGRES_DB=changeme \
    STRAPI_APP_NAME=changeme \
    STRAPI_VERSION=4.23.0 \
    NODE_ENV=development

# Expose port 1337
EXPOSE 1337

# Create working directory and give permissions to node
RUN mkdir -p /strapi && chown -R node:node /strapi
WORKDIR /strapi

# Define health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=10 \
  CMD curl -fs http://localhost:1337/admin || exit 1

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

# Install strapi
RUN npm i -g create-strapi-app@$STRAPI_VERSION

# Add scripts and make them executable
COPY scripts/* /opt/scripts/
RUN chmod +x /opt/scripts/*

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# End of Dockerfile
ENTRYPOINT ["entrypoint.sh"]