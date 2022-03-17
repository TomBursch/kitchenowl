from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import create_access_token, create_refresh_token
from app.models import User
from .schemas import CreateUser

onboarding = Blueprint('onboarding', __name__)


@onboarding.route('', methods=['GET'])
def isOnboarding():
    onboarding = User.count() == 0
    return jsonify({"onboarding": onboarding})


@onboarding.route('', methods=['POST'])
@validate_args(CreateUser)
def onboard(args):
    if User.count() == 0:
        username = args['username'].lower()
        User.create(username, args['password'], args['name'], owner=True)
        ret = {
            'access_token': create_access_token(identity=username),
            'refresh_token': create_refresh_token(identity=username)
        }
        return jsonify(ret)

    return jsonify({'msg': "Onboarding not allowed"}), 403
