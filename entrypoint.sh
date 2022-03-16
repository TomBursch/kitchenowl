#!/bin/sh

# Write ENV to file for flutter (Workaround for not being able to Platform.enviroment inside of flutter web)
echo "BACK_URL=$BACK_URL" > "/var/www/web/kitchenowl/assets/.env"
