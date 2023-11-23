# Reverse proxy configurations

### Traefik v2

This example configuration assumes that you are:

* Running Traefik on the `web` docker network
* Use the entrypoint `websecure` for HTTPS and have configured it for a wildcard SSL certificate
* Have a security@docker middleware (see below)


```yml
version: "3"

services:
  front:
    image: tombursch/kitchenowl-web:latest
    networks:
      - default
      - web
    restart: unless-stopped
    depends_on:
      - back
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=web"
      - "traefik.http.routers.kitchenowl.rule=Host(`your.domain.here`)"
      - "traefik.http.routers.kitchenowl.entrypoints=websecure"
      - 'traefik.http.routers.kitchenowl.middlewares=security@docker' # Use to apply security middlewares

  back:
    image: tombursch/kitchenowl:latest
    networks:
      - default
    restart: unless-stopped
    environment:
      - FRONT_URL=https://your.domain.here
      - JWT_SECRET_KEY=PLEASE_CHANGE_ME
    volumes:
      - kitchenowl_data:/data

networks:
  web:
    external: true

volumes:
  kitchenowl_data:
```

Traefik can add extra security headers to add a level of protection to your KitchenOwl instance. You can specify a middleware in your Traefik docker-compose.yml using labels.

```yml
  labels:
    - 'traefik.http.middlewares.security.headers.addvaryheader=true'
    - 'traefik.http.middlewares.security.headers.sslredirect=true'
    - 'traefik.http.middlewares.security.headers.browserxssfilter=true'
    - 'traefik.http.middlewares.security.headers.contenttypenosniff=true'
    - 'traefik.http.middlewares.security.headers.forcestsheader=true'
    - 'traefik.http.middlewares.security.headers.stsincludesubdomains=true'
    - 'traefik.http.middlewares.security.headers.stspreload=true'
    - 'traefik.http.middlewares.security.headers.stsseconds=63072000'
    - 'traefik.http.middlewares.security.headers.customframeoptionsvalue=SAMEORIGIN'
    - 'traefik.http.middlewares.security.headers.referrerpolicy=same-origin'
```