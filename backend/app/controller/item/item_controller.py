from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from app.errors import InvalidUsage, NotFoundRequest
import app.util.description_splitter as description_splitter
from flask_jwt_extended import jwt_required
from app.models import Item, RecipeItems, Recipe, Category
from .schemas import SearchByNameRequest, UpdateItem, AddItem

item = Blueprint("item", __name__)
itemHousehold = Blueprint("item", __name__)


@itemHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllItems(household_id):
    return jsonify(
        [e.obj_to_dict() for e in Item.all_from_household_by_name(household_id)]
    )


@item.route("/<int:id>", methods=["GET"])
@jwt_required()
def getItem(id: int):
    item = Item.find_by_id(id)
    if not item:
        raise NotFoundRequest()
    item.checkAuthorized()
    return jsonify(item.obj_to_dict())


@item.route("/<int:id>/recipes", methods=["GET"])
@jwt_required()
def getItemRecipes(id: int):
    item = Item.find_by_id(id)
    if not item:
        raise NotFoundRequest()
    item.checkAuthorized()
    recipe = (
        RecipeItems.query.filter(RecipeItems.item_id == id)
        .join(RecipeItems.recipe)  # noqa
        .order_by(Recipe.name)
        .all()
    )
    return jsonify([e.obj_to_recipe_dict() for e in recipe])


@item.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteItemById(id: int):
    item = Item.find_by_id(id)
    if not item:
        raise NotFoundRequest()
    item.checkAuthorized()
    item.delete()
    return jsonify({"msg": "DONE"})


@itemHousehold.route("/search", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(SearchByNameRequest)
def searchItemByName(args: SearchByNameRequest, household_id: int):
    query, description = description_splitter.split(args.query)
    return jsonify(
        [
            e.obj_to_dict() | {"description": description}
            for e in Item.search_name(query, household_id)
        ]
    )


@itemHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddItem)
def addItem(args: AddItem, household_id: int):
    name: str = args.name.strip()[:128]
    if Item.find_by_name(household_id, name):
        raise InvalidUsage()

    item = Item(household_id=household_id, name=name)
    if args.category is not None:
        item.category = Category.find_by_id(args.category.id)
    if args.icon is not None:
        item.icon = args.icon
    item.save()

    return jsonify(item.obj_to_dict())


@item.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateItem)
def updateItem(args: UpdateItem, id: int):
    item = Item.find_by_id(id)
    if not item:
        raise NotFoundRequest()
    item.checkAuthorized()

    if args.category is not None:
        item.category = Category.find_by_id(args.category.id)
    if args.icon is not None:
        item.icon = args.icon
    if args.name is not None and args.name != item.name:
        newName: str = args.name.strip()[:128]
        if not Item.find_by_name(item.household_id, newName):
            item.name = newName
    item.save()

    if args.merge_item_id is not None and args.merge_item_id != id:
        mergeItem = Item.find_by_id(args.merge_item_id)
        if mergeItem:
            item.merge(mergeItem)

    return jsonify(item.obj_to_dict())
