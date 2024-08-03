# Advanced Configuration

There are a few options for advanced users. Customization is done using environment variables.

### Tags

There are three tags available: `latest`, `beta` and `dev`. `latest` is the most current stable release and is the default. `beta` corresponds to the most recent prerelease and might have some experimental features. The `dev` tag is directly build from the main branch and should not be used in production. Release notes can be found on the [releases page](https://github.com/TomBursch/kitchenowl/releases).
Additionally, the releases are tagged, so you can always choose a specific version with `vX.X.X`.

### Backend
- Set up with OpenID Connect: [OIDC](./oidc.md)
- Set up with a PostgreSQL database: [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose-postgres.yml)

Environment variables for `tombursch/kitchenowl` and `tombursch/kitchenowl-backend`:

| Variable                     | Default                    | Description                                                                                                                                           |
| ---------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `JWT_SECRET_KEY`             |                            |                                                                                                                                                       |
| `FRONT_URL`                  |                            | Adds allow origin CORS header for the URL. If set, should exactly match KitchenOwl's URL including the schema (e.g. `https://app.kitchenowl.org`)     |
| `PRIVACY_POLICY_URL`         |                            | Allows to set a custom privacy policy for your server instance                                                                                        |
| `OPEN_REGISTRATION`          | `false`                    | If set allows anyone to create an account on your server                                                                                              |
| `EMAIL_MANDATORY`            | `false`                    | Makes the email a mandatory field when registering (Only relevant if `OPEN_REGISTRATION` is set)                                                      |
| `COLLECT_METRICS`            | `false`                    | Enables a Prometheus metrics endpoint at `/metrics/`. If enabled can be reached over the frontend container on port 9100 (e.g. `front:9100/metrics/`) |
| `METRICS_USER`               | `kitchenowl`               | Metrics basic auth username                                                                                                                           |
| `METRICS_PASSWORD`           | `ZqQtidgC5n3YXb`           | Metrics basic auth password                                                                                                                           |
| `SKIP_UPGRADE_DEFAULT_ITEMS` | `false`                    | On every restart all default items are imported and updated in every household                                                                        |
| `STORAGE_PATH`               | `/data`                    | Images are stored in `STORAGE_PATH/upload`                                                                                                            |
| `DB_DRIVER`                  | `sqlite`                   | Supported: `sqlite` and `postgresql`                                                                                                                  |
| `DB_HOST`                    |                            |                                                                                                                                                       |
| `DB_PORT`                    |                            |                                                                                                                                                       |
| `DB_NAME`                    | `STORAGE_PATH/database.db` | When the driver is `sqlite` this decides where to store the DB                                                                                        |
| `DB_USER`                    |                            |                                                                                                                                                       |
| `DB_PASSWORD`                |                            |                                                                                                                                                       |
| `SMTP_HOST`                  |                            | You can connect to an SMTP server for sending password resets and verifying user emails. This not required.                                           |
| `SMTP_PORT`                  | `465`                      |                                                                                                                                                       |
| `SMTP_USER`                  |                            |                                                                                                                                                       |
| `SMTP_PASS`                  |                            |                                                                                                                                                       |
| `SMTP_FROM`                  |                            |                                                                                                                                                       |
| `SMTP_REPLY_TO`              |                            |                                                                                                                                                       |
| `OIDC_ISSUER`                |                            | More about [OIDC](./oidc.md)                                                                                                                          |
| `OIDC_CLIENT_ID`             |                            |                                                                                                                                                       |
| `OIDC_CLIENT_SECRET`         |                            |                                                                                                                                                       |
| `APPLE_CLIENT_ID`            |                            |                                                                                                                                                       |
| `APPLE_CLIENT_SECRET`        |                            |                                                                                                                                                       |
| `GOOGLE_CLIENT_ID`           |                            |                                                                                                                                                       |
| `GOOGLE_CLIENT_SECRET`       |                            |                                                                                                                                                       |

Additionally, to setting these environment variables you can also override the start command to scale the backend up.
Add the following line or take a look at this exemplary [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose-postgres.yml) file:

```yml
back:
  [...]
  command: --ini wsgi.ini:web --gevent 2000 # default: 100
  [...]
```

Overriding the command is not recommended as we might change the underlying process in the future.

### Frontend

Environment variables for `tombursch/kitchenowl-web`:

| Variable   | Default     | Description                                                                                                                                                          |
| ---------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BACK_URL` | `back:5000` | Allows to set a custom address for the backend. Needs to be an uWSGI protocol endpoint. Should correspond to the name or IP of the backend container and port `5000` |

## Multiservice Setup
All provided examples can be turned into a multiservice setup with just a few changes. This means separating frontend and backend into multiple docker containers.


See [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose.yml)
```yml
version: "3"
services:
  front:
    image: tombursch/kitchenowl-web:latest
    restart: unless-stopped
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
