from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import create_access_token, create_refresh_token
from app.models import User, Settings
from app.service.export_import import importFromLanguage
from .schemas import OnboardSchema

onboarding = Blueprint('onboarding', __name__)


@onboarding.route('', methods=['GET'])
def isOnboarding():
    onboarding = User.count() == 0
    return jsonify({"onboarding": onboarding})


@onboarding.route('', methods=['POST'])
@validate_args(OnboardSchema)
def onboard(args):
    if User.count() == 0:
        if 'planner_feature' in args or 'expenses_feature' in args:
            settings = Settings.get()
            if 'planner_feature' in args:
                settings.planner_feature = args['planner_feature']
            if 'expenses_feature' in args:
                settings.expenses_feature = args['expenses_feature']
            settings.save()
        if 'language' in args:
            importFromLanguage(args['language'])
        username = args['username'].lower()
        User.create(username, args['password'], args['name'], owner=True)
        ret = {
            'access_token': create_access_token(identity=username),
            'refresh_token': create_refresh_token(identity=username)
        }
        return jsonify(ret)

    return jsonify({'msg': "Onboarding not allowed"}), 403
