# Reverse proxy configurations

These are community provided and might need to be adapted to your specific setup.

### HAProxy

Assumes HAProxy is part of your KitchenOwl docker compose stack, and you use the multiservice setup method.

```
global
  log stdout local0

defaults
  mode http
  log global
  option httplog
  option forwardfor if-none
  retries                 3
  timeout http-request    10s
  timeout queue           1m
  timeout connect         10s
  timeout client          1m
  timeout server          1m
  timeout http-keep-alive 10s
  timeout check           10s
  default-server init-addr last,libc,none

resolvers docker
  parse-resolv-conf

#-----------------------#
#  http
#-----------------------#
frontend efeu-http
  bind :::80 v4v6
  bind :::443 v4v6 ssl crt /etc/letsencrypt/live/domain/domain.pem

  redirect scheme https if !{ ssl_fc }

  # hsts max-age is mandatory
  # 16000000 seconds is a bit more than 6 months
  http-response set-header Strict-Transport-Security "max-age=16000000; includeSubDomains; preload;"

  default_backend kitchenowl

backend kitchenowl
  server kitchenowl front:80 resolvers docker

```

### Traefik v2

This example configuration assumes that you are:

- Running Traefik on the `web` docker network
- Use the entrypoint `websecure` for HTTPS and have configured it for a wildcard SSL certificate
- Have a security@docker middleware (see below)

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
      - "traefik.http.routers.kitchenowl.middlewares=security@docker" # Use to apply security middlewares

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
  - "traefik.http.middlewares.security.headers.addvaryheader=true"
  - "traefik.http.middlewares.security.headers.sslredirect=true"
  - "traefik.http.middlewares.security.headers.browserxssfilter=true"
  - "traefik.http.middlewares.security.headers.contenttypenosniff=true"
  - "traefik.http.middlewares.security.headers.forcestsheader=true"
  - "traefik.http.middlewares.security.headers.stsincludesubdomains=true"
  - "traefik.http.middlewares.security.headers.stspreload=true"
  - "traefik.http.middlewares.security.headers.stsseconds=63072000"
  - "traefik.http.middlewares.security.headers.customframeoptionsvalue=SAMEORIGIN"
  - "traefik.http.middlewares.security.headers.referrerpolicy=same-origin"
```

### Apache

The following assumptions are made by this config:

- You have a (sub)domain for your kitchenowl instance. eg: kitchenowl.example.org
- You are running the docker images from the given docker-compose.yml with the "ports" changed from "80:80" to "8080:80"
- You have certbot (or some other letsencrypt client) installed and running on your host system
- You have apache running on your host with the default ports for http/https (80/443)

```
<VirtualHost *:80>
        ServerName kitchenowl.example.org
        ServerAdmin webmaster@example.org

        ErrorLog ${APACHE_LOG_DIR}/kitchenowl_error.log
        CustomLog ${APACHE_LOG_DIR}/kitchenowl_access.log combined

        Redirect permanent / https://kitchenowl.example.org
</VirtualHost>

<VirtualHost *:443>
        ServerName kitchenowl.example.org
        ServerAdmin webmaster@example.org

        <IfModule mod_headers.c>
                Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains; preload"
        </IfModule>


        ErrorLog ${APACHE_LOG_DIR}/kitchenowl_error.log
        CustomLog ${APACHE_LOG_DIR}/kitchenowl_access.log combined

        ProxyPass / http://localhost:8080/
        ProxyPassReverse / http://localhost:8080/

SSLCertificateFile /etc/letsencrypt/live/kitchenowl.exaample.org/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/kitchenowl.example.org/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
```

### Nginx

The following assumptions are made by this config:

- You have a (sub)domain for your kitchenowl instance. eg: kitchenowl.example.org
- You are running the docker images from the given docker-compose.yml with the "ports" changed from "80:80" to "8080:80"
- You have certbot (or some other letsencrypt client) installed and running on your host system
- You have nginx running on your host with the default ports for http/https (80/443)

```
server {
    server_name kitchenowl.example.org;
    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot

    # https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://localhost:8080;
    }

    ssl_certificate /etc/letsencrypt/live/kitchenowl.example.org/fullchain.pem; # managed by
 Certbot
    ssl_certificate_key /etc/letsencrypt/live/kitchenowl.example.org/privkey.pem; # managed 
by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = kitchenowl.example.org) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name kitchenowl.example.org;
    listen 80;
    listen [::]:80;
    return 404; # managed by Certbot
}
```
