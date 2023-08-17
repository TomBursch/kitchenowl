import gevent.monkey
gevent.monkey.patch_all()

from app import app, socketio
import os

from app.config import UPLOAD_FOLDER

if __name__ == "__main__":
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    socketio.run(app, debug=True)
