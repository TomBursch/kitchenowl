#!/bin/sh
flask db upgrade
uwsgi "$@"