# Getting Started

There are multiple ways you can install the KitchenOwl server.

## Official Installation

The official installation method is using [Docker](https://docs.docker.com/engine/install/) and [docker-compose](https://docs.docker.com/compose/):

=== "Docker compose"
    1. Download [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose.yml)
    ```yml
    version: "3"
    services:
      front:
        image: tombursch/kitchenowl-web:latest
        restart: unless-stopped
        # environment:
        #   - BACK_URL=back:5000 # Change this if you rename the containers
        ports:
          - "80:80"
        depends_on:
          - back
      back:
        image: tombursch/kitchenowl-backend:latest
        restart: unless-stopped
        environment:
          - JWT_SECRET_KEY=PLEASE_CHANGE_ME
        volumes:
          - kitchenowl_data:/data

    volumes:
      kitchenowl_data:
    ```
    2. Change the default value for `JWT_SECRET_KEY`
    3. If you want to use PostgreSQL, change the container names, or want to set other settings take a look at the [advanced](advanced.md) options
    4. Run `docker compose up -d`

=== "Docker (All-in-one)"
    1. Create a volume `docker volume create kitchenowl_data`
    2. Run `docker run -d -p 8080:8080 -e "JWT_SECRET_KEY=PLEASE_CHANGE_ME" -v kitchenowl_data:/data tombursch/kitchenowl:latest`

=== "Docker compose (All-in-one)"
    1. Download [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose-single.yml)
    ```yml
    version: "3"
    services:
      back:
        image: tombursch/kitchenowl:latest
        restart: unless-stopped
        ports:
          - "80:8080"
        environment:
          - JWT_SECRET_KEY=PLEASE_CHANGE_ME
        volumes:
          - kitchenowl_data:/data

    volumes:
      kitchenowl_data:
    ```
    2. Change the default value for `JWT_SECRET_KEY`
    3. If you want to use PostgreSQL, use separate containers for front and backend, or want to set other settings take a look at the [advanced](advanced.md) options
    4. Run `docker compose up -d`

!!! danger "Important"
    We recommend running KitchenOwl behind a reverse proxy with HTTPS (e.g. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html) or [Traefik](https://doc.traefik.io/traefik/)). Some [example configurations have been contributed](reverse-proxy.md).

    It is also important that you have HTTP Strict Transport Security enabled and the proper headers applied to your responses or you could be subject to a javascript hijack.

    Please see:

    - [https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security)
    - [https://www.netsparker.com/blog/web-security/http-security-headers/](https://www.netsparker.com/blog/web-security/http-security-headers/)

### Updating KitchenOwl
To upgrade a docker compose stack, you can simply run:

```
docker compose pull
docker compose up -d
```

## Community Installation Methods
Here is a list of community maintained install methods:

- Unraid ([Source](https://codeberg.org/HanSolo97/unraid-templates) AGPL-3.0)
- [Cosmos](https://cosmos-cloud.io/proxy#cosmos-ui/market-listing/cosmos-cloud/KitchenOwl) ([Source](https://github.com/azukaar/cosmos-servapps-official/tree/master/servapps/Kitchenowl) AGPL-3.0)
- TrueNAS SCALE ([Source](https://github.com/truecharts/charts/tree/master/charts/stable/kitchenowl) BSD-3-Clause)
- NixOS ([Source](https://cyberchaos.dev/kloenk/nix/) AGPL-3.0)
