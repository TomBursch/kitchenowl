from datetime import datetime
from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app.models import User, Token
from app.errors import UnauthorizedRequest
from .schemas import Login, CreateLongLivedToken
from app.config import jwt

auth = Blueprint('auth', __name__)


# Callback function to check if a JWT exists in the database blocklist
@jwt.token_in_blocklist_loader
def check_if_token_revoked(jwt_header, jwt_payload: dict) -> bool:
    jti = jwt_payload["jti"]
    token = Token.find_by_jti(jti)
    if (token is not None):
        token.last_used_at = datetime.utcnow()
        token.save()

    return token is None


# Register a callback function that takes whatever object is passed in as the
# identity when creating JWTs and converts it to a JSON serializable format.
@jwt.user_identity_loader
def user_identity_lookup(user: User):
    return user.username


# Register a callback function that loads a user from your database whenever
# a protected route is accessed. This should return any python object on a
# successful lookup, or None if the lookup failed for any reason (for example
# if the user has been deleted from the database).
@jwt.user_lookup_loader
def user_lookup_callback(_jwt_header, jwt_data) -> User:
    identity = jwt_data["sub"]
    return User.find_by_username(identity)


@auth.route('', methods=['POST'])
@validate_args(Login)
def login(args):
    username = args['username'].lower()
    user = User.find_by_username(username)
    if not user or not user.check_password(args['password']):
        raise UnauthorizedRequest(message='Unauthorized')
    device = "Unkown"
    if "device" in args:
        device = args['device']

    # Create refresh token
    refreshToken, refreshModel = Token.create_refresh_token(user, device)

    # Create first access token
    accesssToken, _ = Token.create_access_token(user, refreshModel)

    return jsonify({
        'access_token': accesssToken,
        'refresh_token': refreshToken
    })

# Not in use as we are using the refresh token pattern
# @auth.route('/fresh-login', methods=['POST'])
# @validate_args(Login)
# def fresh_login(args):
#     username = args['username'].lower()
#     user = User.find_by_username(username.lower())
#     if not user or not user.check_password(args['password']):
#         raise UnauthorizedRequest(message='Unauthorized')
#     ret = {'access_token': create_access_token(identity=username, fresh=True)}
#     return jsonify(ret), 200


@auth.route('/refresh', methods=['GET'])
@jwt_required(refresh=True)
def refresh():
    user = User.find_by_username(get_jwt_identity())
    if not user:
        raise UnauthorizedRequest(message='Unauthorized')

    refreshModel = Token.find_by_jti(get_jwt()['jti'])
    # Refresh token rotation
    refreshToken, refreshModel = Token.create_refresh_token(user, oldRefreshToken=refreshModel)

    # Create access token
    accesssToken, _ = Token.create_access_token(user, refreshModel)

    return jsonify({
        'access_token': accesssToken,
        'refresh_token': refreshToken
    })


@auth.route('', methods=['DELETE'])
@jwt_required()
def logout():
    jwt = get_jwt()
    token = Token.find_by_jti(jwt['jti'])
    if not token:
        raise UnauthorizedRequest(message='Unauthorized')

    if token.type == 'access':
        token.refresh_token.delete()
    else:
        token.delete()

    return jsonify({'msg': 'DONE'})


@auth.route('llt', methods=['POST'])
@jwt_required()
@validate_args(CreateLongLivedToken)
def createLongLivedToken(args):
    user = User.find_by_username(get_jwt_identity())
    if not user:
        raise UnauthorizedRequest(message='Unauthorized')

    llToken, _ = Token.create_longlived_token(user, args['device'])

    return jsonify({
        'longlived_token': llToken
    })


@auth.route('llt/<id>', methods=['DELETE'])
@jwt_required()
def deleteLongLivedToken(id):
    user = User.find_by_username(get_jwt_identity())
    if not user:
        raise UnauthorizedRequest(message='Unauthorized')

    token = Token.find_by_id(id)
    if (token.user_id != user.id or token.type != 'llt'):
        raise UnauthorizedRequest(message='Unauthorized')

    token.delete()

    return jsonify({'msg': 'DONE'})
