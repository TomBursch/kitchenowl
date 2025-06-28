# Advanced Configuration

There are a few options for advanced users. Customization is done using environment variables.

### Tags

There are three tags available: `latest`, `beta` and `dev`. `latest` is the most current stable release and is the default. `beta` corresponds to the most recent prerelease and might have some experimental features. The `dev` tag is directly build from the main branch and should not be used in production. Release notes can be found on the [releases page](https://github.com/TomBursch/kitchenowl/releases).
Additionally, the releases are tagged, so you can always choose a specific version with `vX.X.X`.

### Backend

- Set up with OpenID Connect: [OIDC](./oidc.md)
- Set up with a PostgreSQL database: [docker-compose.yml](https://github.com/TomBursch/kitchenowl/blob/main/docker-compose-postgres.yml)

Environment variables for `tombursch/kitchenowl` and `tombursch/kitchenowl-backend`:

| Variable                          | Default                    | Description                                                                                                                                           |
| --------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `JWT_REFRESH_TOKEN_EXPIRES`       | `30`                       | Sets how long (in days) refresh tokens are valid for. Essentially, how long it takes until users are automatically logged out. Must be a number.      |
| `JWT_SECRET_KEY`                  |                            |                                                                                                                                                       |
| `JWT_SECRET_KEY_FILE`             |                            | Reads the JWT secret from the specified file. Should be a path to a file (will override JWT_SECRET_KEY)                                                                              |
| `FRONT_URL`                       |                            | Adds allow origin CORS header for the URL. If set, should exactly match KitchenOwl's URL including the schema (e.g. `https://app.kitchenowl.org`)     |
| `PRIVACY_POLICY_URL`              |                            | Allows to set a custom privacy policy for your server instance                                                                                        |
| `DISABLE_USERNAME_PASSWORD_LOGIN` | `false`                    | If set, allows login only through OpenID Connect (OIDC). Be aware: this won't change the UI and automatically disables `OPEN_REGISTRATION`            |
| `DISABLE_ONBOARDING`              | `false`                    | If set, disables the onboarding process (i.e. creating a user if none are present on the server). If set the first user has to manually be added      |
| `OPEN_REGISTRATION`               | `false`                    | If set, allows anyone to create an account on your server                                                                                             |
| `EMAIL_MANDATORY`                 | `false`                    | Makes the email a mandatory field when registering (Only relevant if `OPEN_REGISTRATION` is set)                                                      |
| `COLLECT_METRICS`                 | `false`                    | Enables a Prometheus metrics endpoint at `/metrics/`. If enabled can be reached over the frontend container on port 9100 (e.g. `front:9100/metrics/`) |
| `METRICS_USER`                    | `kitchenowl`               | Metrics basic auth username                                                                                                                           |
| `METRICS_PASSWORD`                | `ZqQtidgC5n3YXb`           | Metrics basic auth password                                                                                                                           |
| `METRICS_PASSWORD_FILE`           |                            | Allows setting METRICS_PASSWORD from a file path, will override METRICS_PASSWORD                                                                                                                                                      |
| `SKIP_UPGRADE_DEFAULT_ITEMS`      | `false`                    | On every restart all default items are imported and updated in every household                                                                        |
| `STORAGE_PATH`                    | `/data`                    | Images are stored in `STORAGE_PATH/upload`                                                                                                            |
| `DB_DRIVER`                       | `sqlite`                   | Supported: `sqlite` and `postgresql`                                                                                                                  |
| `DB_HOST`                         |                            |                                                                                                                                                       |
| `DB_PORT`                         |                            |                                                                                                                                                       |
| `DB_NAME`                         | `STORAGE_PATH/database.db` | When the driver is `sqlite` this decides where to store the DB                                                                                        |
| `DB_USER`                         |                            |                                                                                                                                                       |
| `DB_USER_FILE`                    |                            | Allows setting DB_USER from a file path, will override DB_USER                                                                                                                                                      |
| `DB_PASSWORD`                     |                            |                                                                                                                                                       |
| `DB_PASSWORD_FILE`                |                            | Allows setting DB_PASSWORD from a file path, will override DB_PASSWORD                                                                                                                                                      |
| `SMTP_HOST`                       |                            | You can connect to an SMTP server for sending password resets and verifying user emails. This is not required.                                        |
| `SMTP_PORT`                       | `465`                      |                                                                                                                                                       |
| `SMTP_USE_TLS`                    | `false`                    | Automatically changes to `true` if `SMTP_PORT` is `587`                                                                                               |
| `SMTP_USER`                       |                            |                                                                                                                                                       |
| `SMTP_USER_FILE`                  |                            | Allows setting SMTP_USER from a file path, will override SMTP_USER                                                                                                                                                      |
| `SMTP_PASS`                       |                            |                                                                                                                                                       |
| `SMTP_PASS_FILE`                  |                            | Allows setting SMTP_PASS from a file path, will override SMTP_PASS                                                                                                                                                      |
| `SMTP_FROM`                       |                            |                                                                                                                                                       |
| `SMTP_REPLY_TO`                   |                            |                                                                                                                                                       |
| `OIDC_ISSUER`                     |                            | More about [OIDC](./oidc.md)                                                                                                                          |
| `OIDC_CLIENT_ID`                  |                            |                                                                                                                                                       |
| `OIDC_CLIENT_SECRET`              |                            |                                                                                                                                                       |
| `OIDC_CLIENT_SECRET_FILE`         |                            | Allows setting OIDC_CLIENT_SECRET from a file path, will override OIDC_CLIENT_SECRET                                                                                                                                                      |
| `APPLE_CLIENT_ID`                 |                            |                                                                                                                                                       |
| `APPLE_CLIENT_SECRET`             |                            |                                                                                                                                                       |
| `APPLE_CLIENT_SECRET_FILE`        |                            | Allows setting APPLE_CLIENT_SECRET from a file path, will override APPLE_CLIENT_SECRET                                                                                                                                                      |
| `GOOGLE_CLIENT_ID`                |                            |                                                                                                                                                       |
| `GOOGLE_CLIENT_SECRET`            |                            |                                                                                                                                                       |
| `GOOGLE_CLIENT_SECRET_FILE`       |                            | Allows setting GOOGLE_CLIENT_SECRET from a file path, will override GOOGLE_CLIENT_SECRET                                                                                                                                                      |
| `LLM_MODEL`                       |                            | Set a custom ingredient detection strategy for scraped recipes from the web. More at [Ingredient Parsing](./ingredient_parsing.md)                    |
| `LLM_API_URL`                     |                            |                                                                                                                                                       |
| `OPENAI_API_KEY`/`OPENROUTER_API_KEY`/etc.|                    | Depends on which provider you choose. See [LiteLLM docs](https://docs.litellm.ai/docs/providers)                                                      |
| `BASE_HREF`                       |                            | Sets the subdirectory KitchenOwl is hosted at. Must begin and end with a slash `/`. Only applicable to `tombursch/kitchenowl`                         |

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

| Variable    | Default     | Description                                                                                                                                                          |
| ----------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BACK_URL`  | `back:5000` | Allows to set a custom address for the backend. Needs to be an uWSGI protocol endpoint. Should correspond to the name or IP of the backend container and port `5000` |
| `BASE_HREF` |             | Sets the subdirectory KitchenOwl is hosted at. Must begin and end with a slash `/`.                                                                                  |

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
