#!/bin/sh
flask db upgrade
mkdir -p $STORAGE_PATH/upload
uwsgi "$@"