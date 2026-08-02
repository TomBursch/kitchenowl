# ruff: noqa: E402

import gevent.monkey

gevent.monkey.patch_all()
import argparse
import os

from app import app, socketio
from app.config import UPLOAD_FOLDER


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--host",
        required=False,
        default=None,
        type=str,
        nargs="?",
        help="Set the host to use. Forwarded to flask.",
    )
    parser.add_argument(
        "--debug",
        required=False,
        default=True,
        type=bool,
        help="Set the debug flag. Forwarded to flask.",
    )
    parser.add_argument(
        "--no-reload",
        action="store_true",
        help="Disable the Flask development server reloader.",
    )

    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_arguments()
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    socketio.run(
        app,
        debug=arguments.debug,
        host=arguments.host,
        use_reloader=not arguments.no_reload,
    )
