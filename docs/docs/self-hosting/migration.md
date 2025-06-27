# Migrating from Older Versions

### v0.6.16
For OIDC users the redirect URI has changed from `kitchenowl:///signin/redirect` to `kitchenowl:/signin/redirect` (See [#644](https://github.com/TomBursch/kitchenowl/issues/644) for the reason why).

### v0.5.0
The frontend is not required any more `tombursch/kitchenowl:latest` is now an all-in-one container that hosts the web application and backend. Take a look at the [installation instructions](index.md) if you want to switch your setup.
Existing setups don't need to be adapted, they will still work like they used to. Although, there now exists a docker image `tombursch/kitchenowl-backend:latest` specifically designed for the split setup.

### v0.4.9
The frontend is now required and using the option to use the backend as an HTTP server has been removed. 

### v0.3.3
Starting from version 0.3.3 `tombursch/kitchenowl-web:latest` ignores the `front_url` environment variable and in most cases is not needed in `tombursch/kitchenowl:latest`.

### v0.0.33
Starting from version 0.0.33 the frontend routes requests to the backend. Thus, only one port has to be accessible. However, the backend can be hosted in standalone mode as it was before (see legacy server install).
