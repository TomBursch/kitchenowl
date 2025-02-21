from app.errors import NotFoundRequest
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app import db
from app.helpers import validate_args, authorize_household
from app.models import Recipe, RecipeHistory, Planner
from .schemas import AddPlannedRecipe, RemovePlannedRecipe
from datetime import datetime, timedelta
import warnings


plannerHousehold = Blueprint("planner", __name__)

def is_within_next_7_days(target_date: datetime) -> bool:
    # Get the current date and time
    now = datetime.now()
    
    # Calculate the date 7 days from now
    seven_days_later = now + timedelta(days=7)
    
    # Check if the target date is within the next 7 days
    return now <= target_date <= seven_days_later

def transform_when_to_day(when: datetime) -> int:
    if is_within_next_7_days(when):
        return when.weekday()

def next_weekday(weekday_number: int) -> datetime:
    # Get today's date
    today = datetime.now()
    
    # Calculate how many days to add to get to the next specified weekday
    days_ahead = (weekday_number - today.weekday() + 7) % 7
    
    # Calculate the next weekday date
    next_date = today + timedelta(days=days_ahead)
    
    return next_date



@plannerHousehold.route("/recipes", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllPlannedRecipes(household_id):
    plannedRecipes = (
        db.session.query(Planner.recipe_id)
        .filter(Planner.household_id == household_id)
        .group_by(Planner.recipe_id)
        .scalar_subquery()
    )
    recipes = (
        Recipe.query.filter(Recipe.id.in_(plannedRecipes)).order_by(Recipe.name).all()
    )
    return jsonify([e.obj_to_full_dict() for e in recipes])


@plannerHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getPlanner(household_id):
    plans = Planner.all_from_household(household_id)
    k = [e.obj_to_full_dict() for e in plans]
    # add day for backwards compatibility
    for d in k:
        d["day"] = transform_when_to_day(d["when"])
    return jsonify(k)


@plannerHousehold.route("/recipe", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddPlannedRecipe)
def addPlannedRecipe(args, household_id):
    recipe = Recipe.find_by_id(args["recipe_id"])
    if not recipe:
        raise NotFoundRequest()
    when = args["when"] if "when" in args else datetime.min
    if "day" in args:
        # if outdated "day" was used, transform it into next date with that weekday
        when = next_weekday(args["day"]).replace(hour=23,minute=59, second=59, microsecond=0)
    planner = Planner.find_by_datetime(household_id=household_id, recipe_id=recipe.id, when=when)
    if not planner:
        if when > datetime.min:
            old = Planner.find_by_datetime(household_id, recipe_id=recipe.id, when=datetime.min)
            if old:
                old.delete()
        elif len(recipe.plans) > 0:
            return jsonify(recipe.obj_to_dict())
        planner = Planner()
        planner.recipe_id = recipe.id
        planner.household_id = household_id
        planner.when = when
        if "yields" in args:
            planner.yields = args["yields"]
        planner.save()

        RecipeHistory.create_added(recipe, household_id)

    return jsonify(recipe.obj_to_dict())


@plannerHousehold.route("/recipe/<int:id>", methods=["DELETE"])
@jwt_required()
@authorize_household()
@validate_args(RemovePlannedRecipe)
def removePlannedRecipeById(args, household_id, id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    
    when = args["when"] if "when" in args else datetime.min
    if "day" in args:
        # if outdated "day" was used, transform it into next date with that weekday
        when = next_weekday(args["day"]).replace(hour=23,minute=59, second=59, microsecond=0)
    planner = Planner.find_by_datetime(household_id, recipe_id=recipe.id, when=when)
    if planner:
        planner.delete()
        RecipeHistory.create_dropped(recipe, household_id)
    return jsonify(recipe.obj_to_dict())


@plannerHousehold.route("/recent-recipes", methods=["GET"])
@jwt_required()
@authorize_household()
def getRecentRecipes(household_id):
    recipes = RecipeHistory.get_recent(household_id)
    return jsonify([e.recipe.obj_to_full_dict() for e in recipes])


@plannerHousehold.route("/suggested-recipes", methods=["GET"])
@jwt_required()
@authorize_household()
def getSuggestedRecipes(household_id):
    # all suggestions
    suggested_recipes = Recipe.find_suggestions(household_id)
    # remove recipes on recent list
    recents = [e.recipe.id for e in RecipeHistory.get_recent(household_id)]
    suggested_recipes = [s for s in suggested_recipes if s.id not in recents]
    # limit suggestions number to maximally 9
    if len(suggested_recipes) > 9:
        suggested_recipes = suggested_recipes[:9]
    return jsonify([r.obj_to_full_dict() for r in suggested_recipes])


@plannerHousehold.route("/refresh-suggested-recipes", methods=["GET", "POST"])
@jwt_required()
@authorize_household()
def getRefreshedSuggestedRecipes(household_id):
    # re-compute suggestion ranking
    Recipe.compute_suggestion_ranking(household_id)
    # return suggested recipes
    return getSuggestedRecipes(household_id=household_id)
