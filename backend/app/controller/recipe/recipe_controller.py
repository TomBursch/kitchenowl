import re
from sqlalchemy import desc, func
from app.config import FRONT_URL
from app.errors import NotFoundRequest
from app.models import Household, RecipeItems, RecipeTags
from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from app import db
from app.helpers import validate_args, authorize_household
from app.models import Recipe, Item, Tag
from app.models.recipe import RecipeVisibility
from app.service.file_has_access_or_download import file_has_access_or_download
from app.service.recipe_scraping import scrape
from .schemas import (
    SearchByNameRequest,
    AddRecipe,
    SearchByTagRequest,
    UpdateRecipe,
    GetAllFilterRequest,
    ScrapeRecipe,
    SuggestionsRecipe,
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


@recipeHousehold.route("/newest/<int:page>", methods=["GET"])
@jwt_required()
def getNewesetPublicRecipesOfHousehold(household_id, page):
    return jsonify(
        [
            e.obj_to_public_dict()
            for e in Recipe.query.join(Recipe.household)
            .filter(
                Recipe.household_id == household_id,
                Recipe.visibility == RecipeVisibility.PUBLIC,
            )
            .order_by(desc(Recipe.id))
            .offset(page * 10)
            .limit(10)
            .all()
        ]
    )


@recipe.route("/<int:id>", methods=["GET"])
@jwt_required(optional=True)
def getRecipeById(id):
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    if recipe.visibility == RecipeVisibility.PRIVATE:
        recipe.checkAuthorized()
        return jsonify(recipe.obj_to_full_dict())

    if recipe.isAuthorized():
        return jsonify(recipe.obj_to_full_dict())

    return jsonify(recipe.obj_to_public_dict())


@recipeHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddRecipe)
def addRecipe(args: AddRecipe, household_id: int):
    recipe = Recipe()
    recipe.name = args.name.strip()[:128]
    recipe.description = args.description
    recipe.household_id = household_id
    if args.time is not None:
        recipe.time = args.time
    if args.cook_time is not None:
        recipe.cook_time = args.cook_time
    if args.prep_time is not None:
        recipe.prep_time = args.prep_time
    if args.yields is not None:
        recipe.yields = args.yields
    if args.source is not None:
        recipe.source = args.source
        localMatch = re.match(
            r"(kitchenowl:\/\/|"
            + re.escape((FRONT_URL or "").removesuffix("/"))
            + r")\/recipe\/(\d+)",
            recipe.source,
        )
        if localMatch:
            # Local recipe
            sourceRecipe = Recipe.find_by_id(int(localMatch.group(2)))
            if sourceRecipe:
                sourceRecipe.server_scrapes = sourceRecipe.server_scrapes + 1
                sourceRecipe.save()
    if args.visibility is not None:
        recipe.visibility = RecipeVisibility(args.visibility)
    if args.photo is not None and args.photo != recipe.photo:
        recipe.photo = file_has_access_or_download(args.photo, recipe.photo)
    if args.server_curated is not None and current_user.admin:
        recipe.server_curated = args.server_curated
    recipe.save()
    if args.items is not None:
        for recipeItem in args.items:
            item = Item.find_by_name(household_id, recipeItem.name)
            if not item:
                item = Item.create_by_name(household_id, recipeItem.name)
            con = RecipeItems(
                description=recipeItem.description, optional=recipeItem.optional
            )
            con.item = item
            con.recipe = recipe
            con.save()
    if args.tags is not None:
        for tagName in args.tags:
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
def updateRecipe(args: UpdateRecipe, id: int):  # noqa: C901
    recipe = Recipe.find_by_id(id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    if args.name is not None:
        recipe.name = args.name.strip()[:128]
    if args.description is not None:
        recipe.description = args.description
    if args.time is not None:
        recipe.time = args.time
    if args.cook_time is not None:
        recipe.cook_time = args.cook_time
    if args.prep_time is not None:
        recipe.prep_time = args.prep_time
    if args.yields is not None:
        recipe.yields = args.yields
    if args.source is not None:
        recipe.source = args.source
    if args.visibility is not None:
        recipe.visibility = RecipeVisibility(args.visibility)
    if args.photo is not None and args.photo != recipe.photo:
        recipe.photo = file_has_access_or_download(args.photo, recipe.photo)
    if args.server_curated is not None and current_user.admin:
        recipe.server_curated = args.server_curated
    recipe.save()
    if args.items is not None:
        for con in recipe.items:
            item_names = [e.name for e in args.items]
            if con.item.name not in item_names:
                con.delete()
        for recipeItem in args.items:
            item = Item.find_by_name(recipe.household_id, recipeItem.name)
            if not item:
                item = Item.create_by_name(recipe.household_id, recipeItem.name)
            con = RecipeItems.find_by_ids(recipe.id, item.id)
            if con:
                if recipeItem.description is not None:
                    con.description = recipeItem.description
                if recipeItem.optional is not None:
                    con.optional = recipeItem.optional
            else:
                con = RecipeItems(
                    description=recipeItem.description,
                    optional=recipeItem.optional,
                )
            con.item = item
            con.recipe = recipe
            con.save()
    if args.tags is not None:
        for con in recipe.tags:
            if con.tag.name not in args.tags:
                con.delete()
        for recipeTag in args.tags:
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
def searchRecipeInHouseholdByName(args: SearchByNameRequest, household_id: int):
    if args.only_ids is not None and args.only_ids:
        return jsonify([e.id for e in Recipe.search_name(args.query, household_id)])
    return jsonify(
        [e.obj_to_full_dict() for e in Recipe.search_name(args.query, household_id)]
    )


@recipeHousehold.route("/filter", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(GetAllFilterRequest)
def getAllFiltered(args: GetAllFilterRequest, household_id: int):
    return jsonify(
        [
            e.obj_to_full_dict()
            for e in Recipe.all_by_name_with_filter(household_id, args.filter)
        ]
    )


@recipeHousehold.route("/scrape", methods=["GET", "POST"])
@jwt_required()
@authorize_household()
@validate_args(ScrapeRecipe)
def scrapeRecipe(args: ScrapeRecipe, household_id: int):
    household = Household.find_by_id(household_id)
    if not household:
        raise NotFoundRequest()

    res = scrape(args.url, household)
    if res:
        return jsonify(res)
    return "Unsupported website", 400


@recipe.route("/discover", methods=["GET"])
@jwt_required()
@validate_args(SuggestionsRecipe)
def suggestedRecipes(args: SuggestionsRecipe):
    queryFilter = [Recipe.visibility == RecipeVisibility.PUBLIC]

    if args.language is not None:
        queryFilter.append(Household.language == args.language)

    tags = (
        RecipeTags.query.join(RecipeTags.tag)
        .join(RecipeTags.recipe)
        .join(Recipe.household)
        .with_entities(Tag.name, func.count().label("count"))
        .filter(*queryFilter)
        .group_by(Tag.name)
        .order_by(desc("count"))
        .limit(10)
        .all()
    )

    return jsonify(
        {
            "popular_tags": [e.name for e in tags],
            "curated": [
                e.obj_to_public_dict()
                for e in Recipe.query.join(Recipe.household)
                .filter(*queryFilter)
                .filter(Recipe.server_curated)
                .order_by(desc(Recipe.id))
                .limit(10)
                .all()
            ],
            "popular": [
                e.obj_to_public_dict()
                for e in Recipe.query.join(Recipe.household)
                .filter(*queryFilter)
                .order_by(
                    desc(Recipe.server_scrapes), Recipe.server_curated, desc(Recipe.id)
                )
                .limit(10)
                .all()
            ],
            "newest": [
                e.obj_to_public_dict()
                for e in Recipe.query.join(Recipe.household)
                .filter(*queryFilter)
                .order_by(desc(Recipe.id))
                .limit(10)
                .all()
            ],
        }
    )


@recipe.route("/discover/curated/<int:page>", methods=["GET"])
@jwt_required()
@validate_args(SuggestionsRecipe)
def curatedRecipes(args: SuggestionsRecipe, page: int):
    queryFilter = [Recipe.visibility == RecipeVisibility.PUBLIC]

    if args.language is not None:
        queryFilter.append(Household.language == args.language)

    return jsonify(
        [
            e.obj_to_public_dict()
            for e in Recipe.query.join(Recipe.household)
            .filter(*queryFilter)
            .filter(Recipe.server_curated)
            .order_by(desc(Recipe.id))
            .offset(page * 10)
            .limit(10)
            .all()
        ]
    )


@recipe.route("/discover/popular/<int:page>", methods=["GET"])
@jwt_required()
@validate_args(SuggestionsRecipe)
def popularRecipes(args: SuggestionsRecipe, page: int):
    queryFilter = [Recipe.visibility == RecipeVisibility.PUBLIC]

    if args.language is not None:
        queryFilter.append(Household.language == args.language)

    return jsonify(
        [
            e.obj_to_public_dict()
            for e in Recipe.query.join(Recipe.household)
            .filter(*queryFilter)
            .order_by(
                desc(Recipe.server_scrapes), Recipe.server_curated, desc(Recipe.id)
            )
            .offset(page * 10)
            .limit(10)
            .all()
        ]
    )


@recipe.route("/discover/newest/<int:page>", methods=["GET"])
@jwt_required()
@validate_args(SuggestionsRecipe)
def newestRecipes(args: SuggestionsRecipe, page: int):
    queryFilter = [Recipe.visibility == RecipeVisibility.PUBLIC]

    if args.language is not None:
        queryFilter.append(Household.language == args.language)

    return jsonify(
        [
            e.obj_to_public_dict()
            for e in Recipe.query.join(Recipe.household)
            .filter(*queryFilter)
            .order_by(desc(Recipe.id))
            .offset(page * 10)
            .limit(10)
            .all()
        ]
    )


@recipe.route("/search", methods=["GET"])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchAllRecipeByName(args: SearchByNameRequest):
    if args.only_ids is not None and args.only_ids:
        return jsonify(
            [
                e.id
                for e in Recipe.search_name(
                    args.query,
                    page=args.page,
                    language=args.language if args.language is not None else None,
                )
            ]
        )
    return jsonify(
        [
            e.obj_to_full_dict()
            for e in Recipe.search_name(
                args.query,
                page=args.page,
                language=args.language if args.language is not None else None,
            )
        ]
    )


@recipe.route("/search-tag", methods=["GET"])
@jwt_required()
@validate_args(SearchByTagRequest)
def searchAllRecipeByTag(args: SearchByTagRequest):
    query = Recipe.query.filter(
        Recipe.visibility == RecipeVisibility.PUBLIC,
        Recipe.tags.any(
            RecipeTags.tag_id.in_(
                db.session.query(Tag.id).filter(Tag.name == args.tag).scalar_subquery()
            )
        ),
    )
    if args.language is not None:
        query = query.join(Recipe.household).filter(Household.language == args.language)

    return jsonify(
        [
            e.obj_to_full_dict()
            for e in query.order_by(Recipe.name).offset(args.page * 10).limit(10).all()
        ]
    )
