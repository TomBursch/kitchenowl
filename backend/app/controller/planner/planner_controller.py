from app.models.recipe_history import RecipeHistory
from app.errors import NotFoundRequest
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.helpers import validate_args
from app.models import Recipe, RecipeHistory
from .schemas import AddPlannedRecipe
from random import randint


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
    if not recipe.planned:
        recipe.planned = True
        recipe.save()
        RecipeHistory.create_added(recipe)
    return jsonify(recipe.obj_to_dict())


@app.route('/planner/recipe/<id>', methods=['DELETE'])
@jwt_required()
def removePlannedRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    if recipe.planned:
        recipe.planned = False
        recipe.save()
        RecipeHistory.create_dropped(recipe)
    return jsonify(recipe.obj_to_dict())


@app.route('/planner/recent-recipes', methods=['GET'])
@jwt_required()
def getRecentRecipes():
    recipes = RecipeHistory.get_recent()
    return jsonify([e.recipe.obj_to_dict() for e in recipes])
    
@app.route('/planner/suggested-recipes', methods=['GET'])
def getSuggestedRecipes():
    # get all unplanned recipes with positive suggestion_score
    recipes = Recipe.query.filter(Recipe.planned == False).filter(Recipe.suggestion_score != 0).all()
    # compute the initial sum of all suggestion_scores
    suggestion_sum = 0
    for r in recipes:
        suggestion_sum += r.suggestion_score
    # randomly suggest one recipe weighted by their score   
    suggested_recipes = []
    while len(suggested_recipes) < 9 and len(recipes) > 0:
        choose = randint(1,suggestion_sum)
        to_be_removed = -1
        for (i,r) in enumerate(recipes):
            choose -= r.suggestion_score
            if choose <= 0:
                suggested_recipes.append(r)
                suggestion_sum -= r.suggestion_score
                to_be_removed = i
                break
        recipes.pop(to_be_removed)
    # jsonfy suggestions
    return jsonify([r.obj_to_dict() for r in suggested_recipes])

