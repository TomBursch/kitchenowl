## :robot: App Install

Get it on [Google Play](https://play.google.com/store/apps/details?id=com.tombursch.kitchenowl) or find the current release for your operating system on the [releases page](https://github.com/TomBursch/kitchenowl/releases).
Please take a quick look at [Tips & Tricks](/tips-and-tricks) to get the best experience in the app.

## 🗄️ Server Install

You can either install only the backend or add the web-app to it. [Docker](https://docs.docker.com/engine/install/) is required.
There are two tags available: `latest` and `dev`. The `dev` tag is directly build from the main branch and should not be used in production.

=== "Backend and Web-app (recommended)"

    Recommended using [docker-compose](https://docs.docker.com/compose/):

    1. Download the [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose.yml)
    ```
    version: "3"
    services:
    front:
        image: tombursch/kitchenowl-web:latest
        environment:
        - FRONT_URL=http://localhost # The url the instance will be access with
        ports:
        - "80:80"
        depends_on:
        - back
        networks:
        - default
    back:
        image: tombursch/kitchenowl:latest
        restart: unless-stopped
        networks:
        - default
        environment:
        - JWT_SECRET_KEY=PLEASE_CHANGE_ME
        - FRONT_URL=http://localhost
        volumes:
        - kitchenowl_data:/data

    volumes:
        kitchenowl_data:

    networks:
        default:
    ```
    2. Change default values such as `JWT_SECRET_KEY` and the URLs (corresponding to the ones your instance will be running on)
    3. Run `docker-compose up -d`

=== "Backend only (legacy)"

    Using docker cli:

    ```
    docker volume create kitchenowl_data
    ```

    ```
    docker run -d -p 5000:80 --name=kitchenowl --restart=unless-stopped -v kitchenowl_data:/data tombursch/kitchenowl:latest
    ```

:exclamation: We recommend running KitchenOwl behind a reverse proxy with https (e.g. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html])) :exclamation:

## ⏫ Migrating from Older Versions
Starting from version 0.0.33 the frontend routes requests to the backend. Thus only one port has to be accessible. However, as before, the backend can be hosted as standalone (see legacy server install).