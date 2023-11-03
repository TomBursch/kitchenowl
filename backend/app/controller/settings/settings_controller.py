from .schemas import SetSettingsSchema
from app.helpers import validate_args, server_admin_required
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.models import Settings

settings = Blueprint("settings", __name__)


@settings.route("", methods=["POST"])
@jwt_required()
@server_admin_required()
def setSettings():
    settings = Settings.get()
    settings.save()
    return jsonify(settings.obj_to_dict())


@settings.route("", methods=["GET"])
@jwt_required()
def getSettings():
    return jsonify(Settings.get().obj_to_dict())
