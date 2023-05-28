from datetime import datetime
from app.helpers import validate_args
from flask import jsonify, Blueprint, request
from flask_jwt_extended import current_user, jwt_required, get_jwt
from app.models import User, Token
from app.errors import UnauthorizedRequest, InvalidUsage
from .schemas import Login, Signup, CreateLongLivedToken
from app.config import jwt, OPEN_REGISTRATION

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
    return user.id


# Register a callback function that loads a user from your database whenever
# a protected route is accessed. This should return any python object on a
# successful lookup, or None if the lookup failed for any reason (for example
# if the user has been deleted from the database).
@jwt.user_lookup_loader
def user_lookup_callback(_jwt_header, jwt_data) -> User:
    identity = jwt_data["sub"]
    return User.find_by_id(identity)


@auth.route('', methods=['POST'])
@validate_args(Login)
def login(args):
    username = args['username'].lower()
    user = User.find_by_username(username)
    if not user or not user.check_password(args['password']):
        raise UnauthorizedRequest(
            message='Unauthorized: IP {} login attemp with wrong username or password'.format(request.remote_addr))
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


if OPEN_REGISTRATION:
    @auth.route('signup', methods=['POST'])
    @validate_args(Signup)
    def signup(args):
        username = args['username'].strip().lower().replace(" ", "")
        user = User.find_by_username(username)
        if user:
            return "Request invalid: username", 400
        if "email" in args:
            user = User.find_by_email(args['email'])
            if user:
                return "Request invalid: email", 400

        user = User.create(
            username=username,
            name=args['name'],
            password=args['password'],
            email=args['email'] if "email" in args else None,
        )

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


@auth.route('/refresh', methods=['GET'])
@jwt_required(refresh=True)
def refresh():
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message='Unauthorized: IP {} refresh attemp with wrong username or password'.format(request.remote_addr))

    refreshModel = Token.find_by_jti(get_jwt()['jti'])
    # Refresh token rotation
    refreshToken, refreshModel = Token.create_refresh_token(
        user, oldRefreshToken=refreshModel)

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
        raise UnauthorizedRequest(
            message='Unauthorized: IP {}'.format(request.remote_addr))

    if token.type == 'access':
        token.refresh_token.delete()
    else:
        token.delete()

    return jsonify({'msg': 'DONE'})


@auth.route('llt', methods=['POST'])
@jwt_required()
@validate_args(CreateLongLivedToken)
def createLongLivedToken(args):
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message='Unauthorized: IP {}'.format(request.remote_addr))

    llToken, _ = Token.create_longlived_token(user, args['device'])

    return jsonify({
        'longlived_token': llToken
    })


@auth.route('llt/<int:id>', methods=['DELETE'])
@jwt_required()
def deleteLongLivedToken(id):
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message='Unauthorized: IP {}'.format(request.remote_addr))

    token = Token.find_by_id(id)
    if (token.user_id != user.id or token.type != 'llt'):
        raise UnauthorizedRequest(
            message='Unauthorized: IP {}'.format(request.remote_addr))

    token.delete()

    return jsonify({'msg': 'DONE'})
