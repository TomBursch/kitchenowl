# Migrating from Older Versions

### v0.4.9
The frontend is now required and using the option to use the backend as an HTTP server has been removed. 

### v0.3.3
Starting from version 0.3.3 `tombursch/kitchenowl-web:latest` ignores the `front_url` environment variable and in most cases is not needed in `tombursch/kitchenowl:latest`.

### v0.0.33
Starting from version 0.0.33 the frontend routes requests to the backend. Thus, only one port has to be accessible. However, the backend can be hosted in standalone mode as it was before (see legacy server install).
