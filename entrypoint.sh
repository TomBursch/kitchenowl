#!/usr/bin/env bash

# Write ENV to file for flutter (Workaround for not being able to Platform.enviroment inside of flutter web)
echo "BACK_URL=$BACK_URL" > "assets/.env"

# Start the server
PORT=80
echo 'Starting server on port' $PORT '...'
python3 -m http.server $PORT

# Exit
echo 'Server exited...'