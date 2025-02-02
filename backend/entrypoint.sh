#!/bin/sh
set -e

# if ipv6 is unavailable, remove it from the wsgi config
ME=$(basename $0)
if [ ! -f "/proc/net/if_inet6" ]; then
    echo "$ME: info: ipv6 not available"
    sed -i 's/\[::\]//g' /usr/src/kitchenowl/wsgi.ini
fi

# patch the web base href if requested
INDEX_HTML=/var/www/web/kitchenowl/index.html
if [ ! -z $BASE_HREF ] && [ -f "$INDEX_HTML" ]; then
    if [[ $BASE_HREF == *"#"* ]]; then
        echo "$ME: error: BASE_HREF must not contain character '#'" >&2
        exit 1
    elif [[ $BASE_HREF != "/"* ]]; then
        echo "$ME: error: BASE_HREF must begin with a forward slash: /example/" >&2
        exit 1
    elif [[ $BASE_HREF != *"/" ]]; then
        echo "$ME: error: BASE_HREF must end with a forward slash: /example/" >&2
        exit 1
    fi
    sed -i "s#<base href=\"/\">#<base href=\"${BASE_HREF}\">#g" "$INDEX_HTML"
fi

mkdir -p $STORAGE_PATH/upload
flask db upgrade
if [ "${SKIP_UPGRADE_DEFAULT_ITEMS}" != "true" ] && [ "${SKIP_UPGRADE_DEFAULT_ITEMS}" != "True" ]; then
    python upgrade_default_items.py
fi
uwsgi "$@"
