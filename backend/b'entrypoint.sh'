#!/bin/sh
mkdir -p $STORAGE_PATH/upload
flask db upgrade
if [ "${SKIP_UPGRADE_DEFAULT_ITEMS}" != "true" ] && [ "${SKIP_UPGRADE_DEFAULT_ITEMS}" != "True" ]; then
    python upgrade_default_items.py
fi
uwsgi "$@"