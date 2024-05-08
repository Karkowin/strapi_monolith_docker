# Strapi Monolith Docker

Strapi Monolith Docker aim to provide fully-working ready-to-use docker image for Strapi. It bundle all NodeJS required librairies, PostgreSQL and some usefull scripts to launch a Strapi project without any setup. 

## Prerequisites

Before you begin, ensure you have Docker installed on your system. You can download and install Docker from [here](https://www.docker.com/get-started).

## Getting Started

### Using Docker CLI

To start using Strapi Monolith Docker, follow these steps:

1. Pull the latest Docker image from the GitHub Container Registry:

```bash
docker pull ghcr.io/karkowin/strapi_monolith_docker:latest
```

2. Run the following command to start the Docker container:

```bash
docker run -d -p 1337:1337 \
  -e POSTGRES_USER=changeme \
  -e POSTGRES_PASSWORD=changeme \
  -e POSTGRES_DB=changeme \
  -e STRAPI_APP_NAME=changeme \
  -e NODE_ENV=development \
  --name strapi_monolith_docker \
  ghcr.io/karkowin/strapi_monolith_docker:latest
```

Note: Replace the environment variable values (`changeme`) with your desired configurations.

### Using Docker Compose

To start using Strapi Monolith Docker, follow these steps:

1. Clone the repository or create a new directory for your Strapi project.

2. Create a `docker-compose.yml` file in your project directory and copy the following configuration:

```yaml
version: "3.9"
services:
  strapi:
    image: ghcr.io/karkowin/strapi_monolith_docker:latest
    container_name: strapi_monolith_docker
    environment:
      - POSTGRES_USER=changeme
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=changeme
      - STRAPI_APP_NAME=changeme
      # - STRAPI_VERSION=4.23.0 # Optional use to specify a version of strapi package
      - NODE_ENV=development # Can be "development" or "production", default is "development"
    ports:
      - "1337:1337"
    volumes:
      - ./strapi:/strapi/
```

3. Replace the environment variable values (`changeme`) with your desired configuration following thoses [requirements](#environment-variables).

4. Run the following command in your project directory to start the Docker container:

```bash
docker-compose up -d
```

5. Once the container is up and running, you can access the Strapi admin panel by navigating to `http://localhost:1337/admin` in your web browser.

## Environment Variables

The following environment variables can be configured in the `docker-compose.yml` file:

- `POSTGRES_USER`: PostgreSQL database user.
- `POSTGRES_PASSWORD`: PostgreSQL database password.
- `POSTGRES_DB`: PostgreSQL database name.
- `STRAPI_APP_NAME`: Name of the Strapi application.
- `STRAPI_VERSION`: Version of the Strapi npm package to install (optional).
- `NODE_ENV`: Environment mode for Strapi (`development` or `production`). Default is `development`.

---

The `POSTGRES_USER` and `POSTGRES_DB` environment variables must follow thoses rules:

- Start with a lowercase letter or an underscore
- Only contain lowercase letters, numbers, and underscores
- Must be equal to or less than 30 characters

**All the environment variables must't contain any special characters except for the `STRAPI_VERSION` wich can contain dots.**

## Project Initialization and Volume Linking

Strapi Monolith Docker offers flexibility in project initialization and volume linking, allowing you to seamlessly start a new project or continue working on an existing one based on your environment variables and linked volumes.

### Automatic Project Creation

When the Strapi Monolith Docker container starts and detects no existing project or if the project directory name does not match the environment variable `STRAPI_APP_NAME`, it automatically creates a new project based on the specified environment variable.

### Volume Linking for Existing Projects

If a project directory exists and its name matches the `STRAPI_APP_NAME` environment variable, the container will link the volume to the existing project directory. This enables you to work on an existing project without losing any data or configurations.

### Backup and Restore Functionality

You can manually trigger a database backup from outside the running container using the following command:

```bash
docker exec -it strapi_monolith_docker sh -c '/opt/scripts/backup.sh'
```

This command creates an SQL backup file under `/strapi/dump/`. Additionally, when creating a container linked with a volume containing a project, Strapi Docker will check if there are backup files present. If the database is empty, it will automatically import the last backup file, ensuring data consistency and integrity.

### Benefits

- **Seamless Workflow**: Start a new project or continue working on an existing one without manual intervention.
- **Data Persistence**: Linked volumes ensure that project data and configurations persist between container restarts.
- **Efficient Development**: Quickly switch between different projects or environments by adjusting environment variables and linked volumes.

### Example

Suppose your `docker-compose.yml` file specifies a linked volume for `/strapi`:

```yaml
services:
  strapi:
    volumes:
      - ./my_strapi_project:/strapi/
```

If `my_strapi_project` contains a directory and it matches the `STRAPI_APP_NAME` environment variable, the container will link the volume to this existing project. Otherwise, it will create a new project named according to the `STRAPI_APP_NAME` variable.

### Note

Ensure that the volume linking and environment variables are configured correctly in your `docker-compose.yml` file to ensure the desired project behavior upon container startup.

## Strapi Plugin Installation

Strapi provide external contents that can be installed manually. The [Marketplace](https://docs.strapi.io/user-docs/plugins/installing-plugins-via-marketplace) is where users can find additional plugins to customize Strapi applications, and additional providers to extend plugins.

### Browsing Plugins

1. Navigate to the admin panel of your Strapi project by visiting `http://localhost:1337/admin` in your web browser.
2. Click on the **"Marketplace"** section in the sidebar menu.

### Copying Installation Command

1. Find the plugin or provider you want to install in the marketplace.
2. Locate the **"Copy install command"** button and click on it.

### Installing Plugins in the Container

To install the plugin in your Strapi Monolith Docker container, follow these steps:

1. Open a terminal window.
2. Use the following command to install the plugin by replacing `<install_command>` with the copied command from the marketplace:

```bash
docker exec -it strapi_monolith_docker sh -c '/opt/scripts/strapi.sh "<install_command>"'
```

3. After running the command, the plugin will be installed in your Strapi project and the server/admin panel will be rebuilt automatically.

## Contributing

Contributions to Strapi Docker are welcome! If you have suggestions, feature requests, or want to report a bug, please open an issue on the [GitHub repository](https://github.com/karkowin/strapi_docker).
