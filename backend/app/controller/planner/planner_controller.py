from app.errors import NotFoundRequest
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.helpers import validate_args
from app.models import Recipe
from .schemas import AddPlannedRecipe


@app.route('/planner/recipes', methods=['GET'])
@jwt_required()
def getAllPlannedRecipes():
    recipes = Recipe.query.filter(Recipe.planned).order_by(Recipe.name).all()
    return jsonify([e.obj_to_dict() for e in recipes])


@app.route('/planner/recipe', methods=['POST'])
@jwt_required()
@validate_args(AddPlannedRecipe)
def addPlannedRecipe(args):
    recipe = Recipe.find_by_id(args['recipe_id'])
    if not recipe:
        raise NotFoundRequest()
    recipe.planned = True
    recipe.save()
    return jsonify(recipe.obj_to_dict())


@app.route('/planner/recipe/<id>', methods=['DELETE'])
@jwt_required()
def removePlannedRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    recipe.planned = False
    recipe.save()
    return jsonify(recipe.obj_to_dict())
