from .schemas import SetSettingsSchema
from app.helpers import validate_args, admin_required
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.models import Settings

settings = Blueprint('settings', __name__)


@settings.route('', methods=['POST'])
@jwt_required()
@admin_required
@validate_args(SetSettingsSchema)
def setSettings(args):
    settings = Settings.get()
    if 'planner_feature' in args:
        settings.planner_feature = args['planner_feature']
    if 'expenses_feature' in args:
        settings.expenses_feature = args['expenses_feature']
    if 'view_ordering' in args:
        settings.view_ordering = args['view_ordering']
    settings.save()
    return jsonify(settings.obj_to_dict())


@settings.route('', methods=['GET'])
@jwt_required()
def getSettings():
    return jsonify(Settings.get().obj_to_dict())
