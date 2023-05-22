# Install
## :robot: App Install

Get it on your favorite app store or find the current release for your operating system on the [releases page](https://github.com/TomBursch/kitchenowl/releases).
Please take a quick look at [Tips & Tricks](tips-and-tricks.md) to get the best experience in the app.

<a href='https://play.google.com/store/apps/details?id=com.tombursch.kitchenowl'>
    <img alt='Get it on Google Play'  src='/img/badges/playstore.png' style="height:50px"/>
</a>
<a href='https://f-droid.org/packages/com.tombursch.kitchenowl/'>
    <img alt='Get it on F-Droid' src='/img/badges/f-droid.png' style="height:50px"/>
</a>
<a href='https://testflight.apple.com/join/x7LhltFw'>
    <img alt='Get it on TestFlight' src='/img/badges/testflight.png' style="height:50px"/>
</a>

## 🗄️ Server Install

You can either install only the backend or add the web-app to it. [Docker](https://docs.docker.com/engine/install/) is required.
There are three tags available: `latest`, `beta` and `dev`. `latest` is the most current stable release and is the default. `beta` corresponds to the most recent prerelease and might have some experimental features. The `dev` tag is directly build from the main branch and should not be used in production. Release notes can be found on the [releases page](https://github.com/TomBursch/kitchenowl/releases).

=== "Backend and Web-app"

    Recommended using [docker-compose](https://docs.docker.com/compose/):

    1. Download the [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose.yml)
    ``` yml
    version: "3"
    services:
        front:
            image: tombursch/kitchenowl-web:latest
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
            volumes:
            - kitchenowl_data:/data

    volumes:
        kitchenowl_data:

    networks:
        default:
    ```
    2. Change the default value for `JWT_SECRET_KEY`
    3. Run `docker-compose up -d`
=== "Advanced settings"
    There are a few options for advanced users. Customize it using environment variables.

    - Frontend `tombursch/kitchenowl-web`:
        - `BACK_URL` (defaut: `back:5000`): Allows to set a custom address for the backend. Needs to be a uwsgi portocol endpoint.
    - Backend `tombursch/kitchenowl`:
        - `FRONT_URL`: Adds custom cors header for the set URL.
        - `HTTP_PORT` (defaut: `80`): Set a custom port for the http server. Usually this should be changed using docker port mapping.
    - Setup using Postgres: [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose-postgres.yml)

!!! danger "Important"
    We recommend running KitchenOwl behind a reverse proxy with HTTPS (e.g. [nginx](https://nginx.org/en/docs/http/configuring_https_servers.html]))

    It is also important that you have HTTP Strict Transport Security enabled and the proper headers applied to your responses or you could be subject to a javascript hijack.

    Please see:

    - [https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security)
    - [https://www.netsparker.com/blog/web-security/http-security-headers/](https://www.netsparker.com/blog/web-security/http-security-headers/)


## ⏫ Migrating from Older Versions

### v0.3.3
Starting from version 0.3.3 `tombursch/kitchenowl-web:latest` ignores the `front_url` environment variable and in most cases is not needed in `tombursch/kitchenowl:latest`.

### v0.0.33
Starting from version 0.0.33 the frontend routes requests to the backend. Thus, only one port has to be accessible. However, the backend can be hosted in standalone mode as it was before (see legacy server install).
