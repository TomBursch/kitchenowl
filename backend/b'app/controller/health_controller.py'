from flask import jsonify
from app import app
from app.config import BACKEND_VERSION, MIN_FRONTEND_VERSION
from app.models import Settings
from flask_jwt_extended import jwt_required, get_jwt_identity


@app.route(
    '/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V',
    methods=['GET']
)
def get_health():
    info = {
        'msg': "OK",
        'version': BACKEND_VERSION,
        'min_frontend_version': MIN_FRONTEND_VERSION,
    }
    settings = Settings.get()
    info.update({
        'planner_feature': settings.planner_feature,
        'expenses_feature': settings.expenses_feature,
    })
    return jsonify(info)
