## 🤖 App Install

Get it on [Google Play](https://play.google.com/store/apps/details?id=com.tombursch.kitchenowl) or find the current release for your operating system on the [releases page](https://github.com/TomBursch/kitchenowl/releases).

## 🗄️ Server Install

You can either install only the backend or add the web-app to it. [Docker](https://docs.docker.com/engine/install/) is required.

=== "Backend only"

    Using docker cli:

    ```
    docker volume create kitchenowl_data
    ```

    ```
    docker run -d -p 5000:5000 --name=kitchenowl --restart=unless-stopped -v kitchenowl_data:/data tombursch/kitchenowl:latest
    ```

=== "Backend and Web-app"

    Recommended using [docker-compose](https://docs.docker.com/compose/):

    1. Download the [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose.yml)
    ```
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
        environment:
        - BACK_URL=http://localhost:5000
    back:
        image: tombursch/kitchenowl:latest
        restart: unless-stopped
        ports:
        - "5000:5000"
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