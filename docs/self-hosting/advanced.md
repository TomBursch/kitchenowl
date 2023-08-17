# Advanced Configuration

There are a few options for advanced users. Customization is done using environment variables.

### Tags

There are three tags available: `latest`, `beta` and `dev`. `latest` is the most current stable release and is the default. `beta` corresponds to the most recent prerelease and might have some experimental features. The `dev` tag is directly build from the main branch and should not be used in production. Release notes can be found on the [releases page](https://github.com/TomBursch/kitchenowl/releases).

### Frontend

Environment variables for `tombursch/kitchenowl-web`:

- `BACK_URL` (default: `back:5000`): Allows to set a custom address for the backend. Needs to be an uWSGI protocol endpoint. Usually corresponds to the name and of the backend container and port `5000`.

### Backend

Environment variables for `tombursch/kitchenowl`:

- `FRONT_URL`: Adds allow origin CORS header for the URL.
- `PRIVACY_POLICY_URL`: Allows to set a custom privacy policy for your server instance.
- `OPEN_REGISTRATION` (default: `false`): If set allows anyone to create an account on your server.
- `EMAIL_MANDATORY` (default: `false`): Make the email a mandatory field when registering (Only relevant if `OPEN_REGISTRATION` is set)
- Set up with a PostgreSQL database: [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose-postgres.yml)

Additionally, to setting these environment variables you can also override the start command to scale the backend up. 
Add the following line or take a look at this exemplary [docker-compose.yml](https://github.com/TomBursch/kitchenowl-backend/blob/main/docker-compose-postgres.yml) file:

```yml
back:
  [...]
  command: wsgi.ini --gevent 2000 # default: 100
  [...]
```
Overriding the command is not recommended as we might change the underlying process in the future.