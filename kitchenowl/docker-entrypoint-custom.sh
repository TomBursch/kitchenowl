#!/bin/sh

set -e

ME=$(basename $0)
entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

# if ipv6 is unavailable, remove it from the nginx template
if [ ! -f "/proc/net/if_inet6" ]; then
    entrypoint_log "$ME: info: ipv6 not available"
    sed -i '/::/d' /etc/nginx/templates/default.conf.template
fi

# patch the web base href if requested
if [ ! -z $BASE_HREF ]; then
    if [[ $BASE_HREF == *"#"* ]]; then
        echo "BASE_HREF must not contain character '#'" >&2
        exit 1
    elif [[ $BASE_HREF != "/"* ]]; then
        echo "BASE_HREF must begin with a forward slash: /example/" >&2
        exit 1
    elif [[ $BASE_HREF != *"/" ]]; then
        echo "BASE_HREF must end with a forward slash: /example/" >&2
        exit 1
    fi
    sed -i "s#<base href=\"/\">#<base href=\"${BASE_HREF}\">#g" /var/www/web/kitchenowl/index.html
fi
