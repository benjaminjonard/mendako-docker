# Dockerfile for Mendako

- This is an image for running Mendako using `Docker`.

- It includes `php7` and `nginx`, you only need to add a `postgres` server.

- *IMPORTANT :* Please note that a running `postgres` server must be available before starting the Mendako container. 

## docker-compose
    version: '3'

    services:
        # Mendako
        mendako:
            image: benjaminjonard/Mendako
            container_name: mendako
            restart: unless-stopped
            ports:
                - 80:80
            environment:
                - DB_DRIVER=pdo_pgsql
                - DB_NAME=mendako
                - DB_HOST=db
                - DB_PORT=5432
                - DB_USER=root
                - DB_PASSWORD=root
                - DB_VERSION=14
                - PHP_TZ=Europe/Paris
                - HTTPS_ENABLED=1 (1 or 0)
            depends_on:
                - db
            volumes:
                - ./docker/volumes/mendako/conf:/conf
                - ./docker/volumes/mendako/uploads:/uploads

        db:
            image: postgres:latest
            container_name: db
            restart: unless-stopped
            environment:
                - POSTGRES_DB=mendako
                - POSTGRES_USER=root
                - POSTGRES_PASSWORD=root
            volumes:
                - "./volumes/postgresql:/var/lib/postgresql/data"
