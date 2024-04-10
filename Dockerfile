# Use Node.js version 20 as base image
FROM node:20

# Set environment variables
ENV POSTGRES_USER=myuser \
    POSTGRES_PASSWORD=mypassword \
    POSTGRES_DB=mydatabase

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

# Initialize PostgreSQL setup
USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';" &&\
    createdb -O $POSTGRES_USER $POSTGRES_DB

# End of Dockerfile
USER node
CMD ["tail", "-f", "/dev/null"]
ENTRYPOINT ["entrypoint.sh"]