from app.helpers import validate_args
from flask import jsonify
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app import app
from app.models import Item, RecipeItems, Recipe
from .schemas import SearchByNameRequest


@app.route('/item', methods=['GET'])
@jwt_required()
def getAllItems():
    return jsonify([e.obj_to_dict() for e in Item.all()])


@app.route('/item/<id>', methods=['GET'])
@jwt_required()
def getItem(id):
    item = Item.find_by_id(id)
    if not item:
        raise NotFoundRequest()
    return jsonify(item.obj_to_dict())


@app.route('/item/<id>/recipes', methods=['GET'])
@jwt_required()
def getItemRecipes(id):
    items = RecipeItems.query.filter(
        RecipeItems.item_id == id, RecipeItems.optional == False).join(
        RecipeItems.recipe).order_by(
        Recipe.name).all()
    return jsonify([e.recipe.obj_to_dict() for e in items])


@app.route('/item/<id>', methods=['DELETE'])
@jwt_required()
def deleteItemById(id):
    Item.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@app.route('/item/search', methods=['GET'])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchItemByName(args):
    return jsonify([e.obj_to_dict() for e in Item.search_name(args['query'])])
