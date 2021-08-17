from app.helpers import validate_args
from flask import jsonify
from flask_jwt_extended import create_access_token, create_refresh_token
from app import app
from app.models import User
from .schemas import CreateUser


@app.route('/onboarding', methods=['GET'])
def isOnboarding():
    onboarding = User.count() == 0
    return jsonify({"onboarding": onboarding})


@app.route('/onboarding', methods=['POST'])
@validate_args(CreateUser)
def onboarding(args):
    if User.count() == 0:
        username = args['username'].lower()
        User.create(username, args['password'], args['name'], owner=True)
        ret = {
            'access_token': create_access_token(identity=username),
            'refresh_token': create_refresh_token(identity=username)
        }
        return jsonify(ret)

    return jsonify({'msg': "Onboarding not allowed"}), 403
