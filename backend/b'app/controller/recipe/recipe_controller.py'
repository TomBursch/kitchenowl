from app.errors import NotFoundRequest
from app.models.recipe import RecipeItems
import json
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.helpers import validate_args
from app.models import Recipe, Item
from .schemas import SearchByNameRequest, AddItemByName, RemoveItem, AddRecipe, UpdateRecipe


@app.route('/recipe', methods=['GET'])
@jwt_required()
def getAllRecipes():
    return jsonify([e.obj_to_full_dict() for e in Recipe.all_by_name()])


@app.route('/recipe/<id>', methods=['GET'])
@jwt_required()
def getRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    return jsonify(recipe.obj_to_full_dict())


@app.route('/recipe', methods=['POST'])
@jwt_required()
@validate_args(AddRecipe)
def addRecipe(args):
    recipe = Recipe()
    recipe.name = args['name']
    recipe.description = args['description']
    recipe.save()
    if 'items' in args:
        for recipeItem in args['items']:
            item = Item.find_by_name(recipeItem['name'])
            if not item:
                item = Item.create_by_name(recipeItem['name'])
            con = RecipeItems(
                description=recipeItem['description'],
                optional=recipeItem['optional']
            )
            con.item = item
            con.recipe = recipe
            con.save()
    return jsonify(recipe.obj_to_dict())


@app.route('/recipe/<id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateRecipe)
def updateRecipe(args, id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    if 'name' in args and args['name']:
        recipe.name = args['name']
    if 'description' in args and args['description']:
        recipe.description = args['description']
    recipe.save()
    if 'items' in args:
        for con in recipe.items:
            item_names = [e['name'] for e in args['items']]
            if not con.item.name in item_names:
                con.delete()
        for recipeItem in args['items']:
            item = Item.find_by_name(recipeItem['name'])
            if not item:
                item = Item.create_by_name(recipeItem['name'])
            con = RecipeItems.find_by_ids(recipe.id, item.id)
            if con:
                if 'description' in recipeItem and recipeItem['description']:
                    con.description = recipeItem['description']
                if 'optional' in recipeItem:
                    con.optional = recipeItem['optional']
            else:
                con = RecipeItems(
                    description=recipeItem['description'],
                    optional=recipeItem['optional']
                )
            con.item = item
            con.recipe = recipe
            con.save()
    return jsonify(recipe.obj_to_dict())


@app.route('/recipe/<id>', methods=['DELETE'])
@jwt_required()
def deleteRecipeById(id):
    Recipe.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@app.route('/recipe/search', methods=['GET'])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchRecipeByName(args):
    return jsonify([e.obj_to_dict() for e in Recipe.search_name(args['query'])])


# @app.route('/recipe/<id>/item', methods=['POST'])
# @jwt_required()
# @validate_args(AddItemByName)
# def addRecipeItemByName(args, id):
#     recipe = Recipe.find_by_id(id)
#     if not recipe:
#         return jsonify(), 404
#     item = Item.find_by_name(args['name'])
#     if not item:
#         item = Item.create_by_name(args['name'])

#     description = args['description'] if 'description' in args else ''
#     con = RecipeItems(description=description)
#     con.item = item
#     recipe.items.append(con)
#     recipe.save()
#     return jsonify(item.obj_to_dict())


# @app.route('/recipe/<id>/item', methods=['DELETE'])
# @jwt_required()
# @validate_args(RemoveItem)
# def removeRecipeItem(args, id):
#     recipe = Recipe.find_by_id(id)
#     if not recipe:
#         return jsonify(), 404
#     item = Item.find_by_id(args['item_id'])
#     if not item:
#         item = Item.create_by_name(args['name'])

#     con = RecipeItems.find_by_ids(id, args['item_id'])
#     con.delete()
#     return jsonify({'msg': "DONE"})
