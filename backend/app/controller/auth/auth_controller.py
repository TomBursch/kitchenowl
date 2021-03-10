from app.helpers import validate_args
from flask import jsonify
from flask_jwt_extended import jwt_required, create_access_token, create_refresh_token, get_jwt_identity
from app.config import app
from app.models import User
from app.errors import UnauthorizedRequest
from .schemas import Login


@app.route('/auth', methods=['POST'])
@validate_args(Login)
def login(args):
    username = args['username'].lower()
    user = User.find_by_username(username)
    if not user or not user.check_password(args['password']):
        raise UnauthorizedRequest(message='Unauthorized')
    ret = {
        'access_token': create_access_token(identity=username),
        'refresh_token': create_refresh_token(identity=username)
    }
    return jsonify(ret)


@app.route('/auth/fresh-login', methods=['POST'])
@validate_args(Login)
def fresh_login(args):
    username = args['username'].lower()
    user = User.find_by_username(username.lower())
    if not user or not user.check_password(args['password']):
        raise UnauthorizedRequest(message='Unauthorized')
    ret = {'access_token': create_access_token(identity=username, fresh=True)}
    return jsonify(ret), 200


@app.route('/auth/refresh', methods=['GET'])
@jwt_required(refresh=True)
def refresh():
    current_user = get_jwt_identity()
    ret = {
        'access_token': create_access_token(identity=current_user)
    }
    return jsonify(ret)
