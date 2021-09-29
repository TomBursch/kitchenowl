from .schemas import SetSettingsSchema
from app.helpers import validate_args, admin_required
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.models import Settings


@app.route('/settings', methods=['POST'])
@jwt_required()
@admin_required
@validate_args(SetSettingsSchema)
def setSettings(args):
    settings = Settings.get()
    if 'planner_feature' in args:
        settings.planner_feature = args['planner_feature']
    if 'expenses_feature' in args:
        settings.expenses_feature = args['expenses_feature']
    settings.save()
    return jsonify(settings.obj_to_dict())


@app.route('/settings', methods=['GET'])
@jwt_required()
def getSettings():
    return jsonify(Settings.get().obj_to_dict())
