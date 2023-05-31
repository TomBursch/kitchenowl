#!/bin/sh
mkdir -p $STORAGE_PATH/upload
flask db upgrade
#python upgrade_default_items.py
uwsgi "$@"