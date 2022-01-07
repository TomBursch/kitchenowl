from app.helpers import validate_args
from flask import jsonify
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app import app
from app.models import Tag, RecipeTags, Recipe
from .schemas import SearchByNameRequest, AddTag


@app.route('/tag', methods=['GET'])
@jwt_required()
def getAllTags():
    return jsonify([e.obj_to_dict() for e in Tag.all()])


@app.route('/tag/<id>', methods=['GET'])
@jwt_required()
def getTag(id):
    tag = Tag.find_by_id(id)
    if not tag:
        raise NotFoundRequest()
    return jsonify(tag.obj_to_dict())


@app.route('/tag/<id>/recipes', methods=['GET'])
@jwt_required()
def getTagRecipes(id):
    tags = RecipeTags.query.filter(
        RecipeTags.tag_id == id).join(
        RecipeTags.recipe).order_by(
        Recipe.name).all()
    return jsonify([e.recipe.obj_to_dict() for e in tags])


@app.route('/tag', methods=['POST'])
@jwt_required()
@validate_args(AddTag)
def addTag(args):
    tag = Tag()
    tag.name = args['name']
    tag.save()
    return jsonify(tag.obj_to_dict())


@app.route('/tag/<id>', methods=['DELETE'])
@jwt_required()
def deleteTagById(id):
    Tag.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@app.route('/tag/search', methods=['GET'])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchTagByName(args):
    return jsonify([e.obj_to_dict() for e in Tag.search_name(args['query'])])
