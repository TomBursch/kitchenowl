import re

from app.errors import NotFoundRequest, InvalidUsage
from app.models import Household, RecipeItems, RecipeTags
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.helpers import validate_args, authorize_household
from app.models import Recipe, Item, Tag
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import SchemaOrgException, NoSchemaFoundInWildMode
from app.service.file_has_access_or_download import file_has_access_or_download
from app.service.ingredient_parsing import parseIngredients
from .schemas import (
    SearchByNameRequest,
    AddRecipe,
    UpdateRecipe,
    GetAllFilterRequest,
    ScrapeRecipe,
)

recipe = Blueprint("recipe", __name__)
recipeHousehold = Blueprint("recipe", __name__)


@recipeHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllRecipes(household_id):
    return jsonify(
        [e.obj_to_full_dict() for e in Recipe.all_from_household_by_name(household_id)]
    )


@recipe.route("/<int:id>", methods=["GET"])
@jwt_required(optional=True)
def getRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    if not recipe.public:
        recipe.checkAuthorized()
    return jsonify(recipe.obj_to_full_dict())


@recipeHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddRecipe)
def addRecipe(args, household_id):
    recipe = Recipe()
    recipe.name = args["name"]
    recipe.description = args["description"]
    recipe.household_id = household_id
    if "time" in args:
        recipe.time = args["time"]
    if "cook_time" in args:
        recipe.cook_time = args["cook_time"]
    if "prep_time" in args:
        recipe.prep_time = args["prep_time"]
    if "yields" in args:
        recipe.yields = args["yields"]
    if "source" in args:
        recipe.source = args["source"]
    if "public" in args:
        recipe.public = args["public"]
    if "photo" in args and args["photo"] != recipe.photo:
        recipe.photo = file_has_access_or_download(args["photo"], recipe.photo)
    recipe.save()
    if "items" in args:
        for recipeItem in args["items"]:
            item = Item.find_by_name(household_id, recipeItem["name"])
            if not item:
                item = Item.create_by_name(household_id, recipeItem["name"])
            con = RecipeItems(
                description=recipeItem["description"], optional=recipeItem["optional"]
            )
            con.item = item
            con.recipe = recipe
            con.save()
    if "tags" in args:
        for tagName in args["tags"]:
            tag = Tag.find_by_name(household_id, tagName)
            if not tag:
                tag = Tag.create_by_name(household_id, tagName)
            con = RecipeTags()
            con.tag = tag
            con.recipe = recipe
            con.save()
    return jsonify(recipe.obj_to_full_dict())


@recipe.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateRecipe)
def updateRecipe(args, id):  # noqa: C901
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    if "name" in args:
        recipe.name = args["name"]
    if "description" in args:
        recipe.description = args["description"]
    if "time" in args:
        recipe.time = args["time"]
    if "cook_time" in args:
        recipe.cook_time = args["cook_time"]
    if "prep_time" in args:
        recipe.prep_time = args["prep_time"]
    if "yields" in args:
        recipe.yields = args["yields"]
    if "source" in args:
        recipe.source = args["source"]
    if "public" in args:
        recipe.public = args["public"]
    if "photo" in args and args["photo"] != recipe.photo:
        recipe.photo = file_has_access_or_download(args["photo"], recipe.photo)
    recipe.save()
    if "items" in args:
        for con in recipe.items:
            item_names = [e["name"] for e in args["items"]]
            if con.item.name not in item_names:
                con.delete()
        for recipeItem in args["items"]:
            item = Item.find_by_name(recipe.household_id, recipeItem["name"])
            if not item:
                item = Item.create_by_name(recipe.household_id, recipeItem["name"])
            con = RecipeItems.find_by_ids(recipe.id, item.id)
            if con:
                if "description" in recipeItem:
                    con.description = recipeItem["description"]
                if "optional" in recipeItem:
                    con.optional = recipeItem["optional"]
            else:
                con = RecipeItems(
                    description=recipeItem["description"],
                    optional=recipeItem["optional"],
                )
            con.item = item
            con.recipe = recipe
            con.save()
    if "tags" in args:
        for con in recipe.tags:
            if con.tag.name not in args["tags"]:
                con.delete()
        for recipeTag in args["tags"]:
            tag = Tag.find_by_name(recipe.household_id, recipeTag)
            if not tag:
                tag = Tag.create_by_name(recipe.household_id, recipeTag)
            con = RecipeTags.find_by_ids(recipe.id, tag.id)
            if not con:
                con = RecipeTags()
                con.tag = tag
                con.recipe = recipe
                con.save()
    return jsonify(recipe.obj_to_full_dict())


@recipe.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()
    recipe.delete()
    return jsonify({"msg": "DONE"})


@recipeHousehold.route("/search", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(SearchByNameRequest)
def searchRecipeByName(args, household_id):
    if "only_ids" in args and args["only_ids"]:
        return jsonify([e.id for e in Recipe.search_name(household_id, args["query"])])
    return jsonify(
        [e.obj_to_full_dict() for e in Recipe.search_name(household_id, args["query"])]
    )


@recipeHousehold.route("/filter", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(GetAllFilterRequest)
def getAllFiltered(args, household_id):
    return jsonify(
        [
            e.obj_to_full_dict()
            for e in Recipe.all_by_name_with_filter(household_id, args["filter"])
        ]
    )


@recipeHousehold.route("/scrape", methods=["GET", "POST"])
@jwt_required()
@authorize_household()
@validate_args(ScrapeRecipe)
def scrapeRecipe(args, household_id):
    household = Household.find_by_id(household_id)
    if not household:
        raise NotFoundRequest()

    try:
        scraper = scrape_html(args["url"], wild_mode=True)
    except:
        return "Unsupported website", 400
    recipe = Recipe()
    recipe.name = scraper.title()
    try:
        recipe.time = int(scraper.total_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        recipe.cook_time = int(scraper.cook_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        recipe.prep_time = int(scraper.prep_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        yields = re.search(r"\d*", scraper.yields())
        if yields:
            recipe.yields = int(yields.group())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    description = ""
    try:
        description = scraper.description() + "\n\n"
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        description = description + scraper.instructions()
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    recipe.description = description
    recipe.photo = scraper.image()
    recipe.source = args["url"]
    items = {}
    for ingredient in parseIngredients(scraper.ingredients(), household.language):
        name = ingredient.name if ingredient.name else ingredient.originalText
        item = Item.find_name_starts_with(household_id, name)
        if item:
            items[ingredient.originalText] = item.obj_to_dict() | {
                "description": ingredient.description,
                "optional": False,
            }
        else:
            items[ingredient.originalText] = None
    return jsonify(
        {
            "recipe": recipe.obj_to_dict(),
            "items": items,
        }
    )
