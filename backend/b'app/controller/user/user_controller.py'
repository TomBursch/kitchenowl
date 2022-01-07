from app.errors import NotFoundRequest, UnauthorizedRequest
from app.helpers.admin_required import admin_required
from app.helpers import validate_args
from flask import jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import app
from app.models import User
from .schemas import CreateUser, UpdateUser


@app.route('/users', methods=['GET'])
@jwt_required()
def getAllUsers():
    return jsonify([e.obj_to_dict(skip_columns=['password']) for e in User.all_by_name()])


@app.route('/user', methods=['GET'])
@jwt_required()
def getLoggedInUser():
    return jsonify(User.find_by_username(get_jwt_identity()).obj_to_dict(skip_columns=['password']))


@app.route('/user/<id>', methods=['GET'])
@jwt_required()
@admin_required
def getUserById(id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    return jsonify(user.obj_to_dict(skip_columns=['password']))


@app.route('/user/<id>', methods=['DELETE'])
@jwt_required()
@admin_required
def deleteUserById(id):
    user = User.find_by_id(id)
    if not user or user.owner:
        raise UnauthorizedRequest(
            message='user_not_allowed'
        )
    User.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@app.route('/user', methods=['POST'])
@jwt_required()
@validate_args(UpdateUser)
def updateUser(args):
    user = User.find_by_username(get_jwt_identity())
    if not user:
        raise NotFoundRequest()
    if 'name' in args and args['name']:
        user.name = args['name']
    if 'password' in args and args['password']:
        user.set_password(args['password'])
    user.save()
    return jsonify({'msg': 'DONE'})


@app.route('/user/<id>', methods=['POST'])
@jwt_required()
@admin_required
@validate_args(UpdateUser)
def updateUserById(args, id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    if 'name' in args and args['name']:
        user.name = args['name']
    if 'password' in args and args['password']:
        user.set_password(args['password'])
    if 'admin' in args:
        user.admin = args['admin'] or user.owner
    user.save()
    return jsonify({'msg': 'DONE'})


@app.route('/new-user', methods=['POST'])
@jwt_required()
@admin_required
@validate_args(CreateUser)
def createUser(args):
    User.create(args['username'].lower(), args['password'], args['name'])
    return jsonify({'msg': 'DONE'})
