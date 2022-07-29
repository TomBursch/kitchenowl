from app.errors import NotFoundRequest
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.helpers import validate_args
from app.models import Recipe, RecipeHistory
from .schemas import AddPlannedRecipe, RemovePlannedRecipe

planner = Blueprint('planner', __name__)


@planner.route('/recipes', methods=['GET'])
@jwt_required()
def getAllPlannedRecipes():
    recipes = Recipe.query.filter(Recipe.planned).order_by(Recipe.name).all()
    return jsonify([e.obj_to_full_dict() for e in recipes])


@planner.route('/recipe', methods=['POST'])
@jwt_required()
@validate_args(AddPlannedRecipe)
def addPlannedRecipe(args):
    recipe = Recipe.find_by_id(args['recipe_id'])
    if not recipe:
        raise NotFoundRequest()
    if 'day' in args:
        recipe.planned_days = recipe.planned_days.copy()
        recipe.planned_days.add(args['day'])
    else:
        recipe.planned_days = set()
    recipe.planned = True
    recipe.save()
    RecipeHistory.create_added(recipe)
    return jsonify(recipe.obj_to_dict())


@planner.route('/recipe/<id>', methods=['DELETE'])
@jwt_required()
@validate_args(RemovePlannedRecipe)
def removePlannedRecipeById(args, id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    if recipe.planned:
        if 'day' in args:
            recipe.planned_days = recipe.planned_days.copy()
            recipe.planned_days.discard(args['day'])
        else:
            recipe.planned_days = {}
        recipe.planned = len(recipe.planned_days) > 0
        recipe.save()
        RecipeHistory.create_dropped(recipe)
    return jsonify(recipe.obj_to_dict())


@planner.route('/recent-recipes', methods=['GET'])
@jwt_required()
def getRecentRecipes():
    recipes = RecipeHistory.get_recent()
    return jsonify([e.recipe.obj_to_full_dict() for e in recipes])


@planner.route('/suggested-recipes', methods=['GET'])
@jwt_required()
def getSuggestedRecipes():
    # all suggestions
    suggested_recipes = Recipe.find_suggestions()
    # remove recipes on recent list
    recents = [e.recipe.id for e in RecipeHistory.get_recent()]
    suggested_recipes = [s for s in suggested_recipes if s.id not in recents]
    # limit suggestions number to maximally 9
    if len(suggested_recipes) > 9:
        suggested_recipes = suggested_recipes[:9]
    return jsonify([r.obj_to_full_dict() for r in suggested_recipes])


@planner.route('/refresh-suggested-recipes', methods=['GET'])
@jwt_required()
def getRefreshedSuggestedRecipes():
    # re-compute suggestion ranking
    Recipe.compute_suggestion_ranking()
    # return suggested recipes
    return getSuggestedRecipes()
