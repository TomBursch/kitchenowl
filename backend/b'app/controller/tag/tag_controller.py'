from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app.models import Tag, RecipeTags, Recipe
from .schemas import AddTag, UpdateTag

tag = Blueprint('tag', __name__)
tagHousehold = Blueprint('tag', __name__)


@tagHousehold.route('', methods=['GET'])
@jwt_required()
@authorize_household()
def getAllTags(household_id):
    return jsonify([e.obj_to_dict() for e in Tag.all_from_household_by_name(household_id)])


@tag.route('/<int:id>', methods=['GET'])
@jwt_required()
def getTag(id):
    tag = Tag.find_by_id(id)
    if not tag:
        raise NotFoundRequest()
    tag.checkAuthorized()
    return jsonify(tag.obj_to_dict())


@tag.route('/<int:id>/recipes', methods=['GET'])
@jwt_required()
def getTagRecipes(id):
    tag = Tag.find_by_id(id)
    if not tag:
        raise NotFoundRequest()
    tag.checkAuthorized()

    tags = RecipeTags.query.filter(
        RecipeTags.tag_id == id).join(
        RecipeTags.recipe).order_by(
        Recipe.name).all()
    return jsonify([e.recipe.obj_to_dict() for e in tags])


@tagHousehold.route('', methods=['POST'])
@jwt_required()
@authorize_household()
@validate_args(AddTag)
def addTag(args, household_id):
    tag = Tag()
    tag.name = args['name']
    tag.household_id = household_id
    tag.save()
    return jsonify(tag.obj_to_dict())


@tag.route('/<int:id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateTag)
def updateTag(args, id):
    tag = Tag.find_by_id(id)
    if not tag:
        raise NotFoundRequest()
    tag.checkAuthorized()

    if 'name' in args:
        tag.name = args['name']

    tag.save()

    if 'merge_tag_id' in args and args['merge_tag_id'] != id:
        mergeTag = Tag.find_by_id(args['merge_tag_id'])
        if mergeTag:
            tag.merge(mergeTag)

    return jsonify(tag.obj_to_dict())


@tag.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deleteTagById(id):
    tag = Tag.find_by_id(id)
    if not tag:
        raise NotFoundRequest()
    tag.checkAuthorized()
    tag.delete()
    return jsonify({'msg': 'DONE'})
