#!/bin/sh
flask db upgrade
mkdir -p $STORAGE_PATH/upload
python upgrade_default_items.py
uwsgi "$@"