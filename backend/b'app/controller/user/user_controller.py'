from app.errors import NotFoundRequest, UnauthorizedRequest
from app.helpers.server_admin_required import server_admin_required
from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from app.models import User, File
from .schemas import CreateUser, UpdateUser, SearchByNameRequest


user = Blueprint('user', __name__)


@user.route('/all', methods=['GET'])
@jwt_required()
def getAllUsers():
    return jsonify([e.obj_to_dict() for e in User.all_by_name()])


@user.route('', methods=['GET'])
@jwt_required()
def getLoggedInUser():
    return jsonify(current_user.obj_to_full_dict())


@user.route('/<int:id>', methods=['GET'])
@jwt_required()
@server_admin_required()
def getUserById(id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    return jsonify(user.obj_to_dict())


@user.route('', methods=['DELETE'])
@jwt_required()
def deleteUser():
    if not current_user:
        raise UnauthorizedRequest(
            message='Cannot delete this user'
        )
    current_user.delete()
    return jsonify({'msg': 'DONE'})


@user.route('/<int:id>', methods=['DELETE'])
@jwt_required()
@server_admin_required()
def deleteUserById(id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    user.delete()
    return jsonify({'msg': 'DONE'})


@user.route('', methods=['POST'])
@jwt_required()
@validate_args(UpdateUser)
def updateUser(args):
    user: User = current_user
    if not user:
        raise NotFoundRequest()
    if 'name' in args:
        user.name = args['name']
    if 'password' in args:
        user.set_password(args['password'])
    if 'photo' in args:
        f = File.find(args['photo'])
        if f and f.created_by == user.id:
            user.photo = f.filename
    user.save()
    return jsonify({'msg': 'DONE'})


@user.route('/<int:id>', methods=['POST'])
@jwt_required()
@server_admin_required()
@validate_args(UpdateUser)
def updateUserById(args, id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    if 'name' in args:
        user.name = args['name']
    if 'password' in args:
        user.set_password(args['password'])
    if 'photo' in args:
        user.photo = args['photo']
    if 'admin' in args:
        user.admin = args['admin']
    user.save()
    return jsonify({'msg': 'DONE'})


@user.route('/new', methods=['POST'])
@jwt_required()
@server_admin_required()
@validate_args(CreateUser)
def createUser(args):
    User.create(args['username'].lower(), args['password'], args['name'])
    return jsonify({'msg': 'DONE'})


@user.route('/search', methods=['GET'])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchUser(args):
    return jsonify([e.obj_to_dict() for e in User.search_name(args['query'])])
