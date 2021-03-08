from flask import jsonify
from app import app
from app.config import BACKEND_VERSION, MIN_FRONTEND_VERSION


@app.route(
    '/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V',
    methods=['GET']
)
def get_health():
    return jsonify({'msg': "OK", 'version': BACKEND_VERSION, 'min_frontend_version': MIN_FRONTEND_VERSION})
