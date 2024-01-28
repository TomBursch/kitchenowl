from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from app import db
from app.models import (
    Item,
    Shoppinglist,
    History,
    Status,
    Association,
    ShoppinglistItems,
)
from app.helpers import validate_args, authorize_household
from .schemas import (
    RemoveItem,
    UpdateDescription,
    AddItemByName,
    CreateList,
    AddRecipeItems,
    GetItems,
    UpdateList,
    GetRecentItems,
    RemoveItems,
)
from app.errors import NotFoundRequest, InvalidUsage
from datetime import datetime, timedelta, timezone
import app.util.description_merger as description_merger
from app import socketio


shoppinglist = Blueprint("shoppinglist", __name__)
shoppinglistHousehold = Blueprint("shoppinglist", __name__)


@shoppinglistHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(CreateList)
def createShoppinglist(args, household_id):
    return jsonify(
        Shoppinglist(name=args["name"], household_id=household_id).save().obj_to_dict()
    )


@shoppinglistHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getShoppinglists(household_id):
    shoppinglists = Shoppinglist.all_from_household(household_id)
    return jsonify([e.obj_to_dict() for e in shoppinglists])


@shoppinglist.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateList)
def updateShoppinglist(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    if "name" in args:
        shoppinglist.name = args["name"]

    shoppinglist.save()
    return jsonify(shoppinglist.obj_to_dict())


@shoppinglist.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteShoppinglist(id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()
    if shoppinglist.isDefault():
        raise InvalidUsage()
    shoppinglist.delete()

    return jsonify({"msg": "DONE"})


@shoppinglist.route("/<int:id>/item/<int:item_id>", methods=["POST", "PUT"])
@jwt_required()
@validate_args(UpdateDescription)
def updateItemDescription(args, id, item_id):
    con = ShoppinglistItems.find_by_ids(id, item_id)
    if not con:
        shoppinglist = Shoppinglist.find_by_id(id)
        item = Item.find_by_id(item_id)
        if not item or not shoppinglist:
            raise NotFoundRequest()
        if shoppinglist.household_id != item.household_id:
            raise InvalidUsage()
        con = ShoppinglistItems()
        con.shoppinglist = shoppinglist
        con.item = item
        con.created_by = current_user.id
    con.shoppinglist.checkAuthorized()

    con.description = args["description"] or ""
    con.save()
    socketio.emit(
        "shoppinglist_item:add",
        {
            "item": con.obj_to_item_dict(),
            "shoppinglist": con.shoppinglist.obj_to_dict(),
        },
        to=con.shoppinglist.household_id,
    )
    return jsonify(con.obj_to_item_dict())


@shoppinglist.route("/<int:id>/items", methods=["GET"])
@jwt_required()
@validate_args(GetItems)
def getAllShoppingListItems(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    orderby = [Item.name]
    if "orderby" in args:
        if args["orderby"] == 1:
            orderby = [Item.ordering == 0, Item.ordering]
        elif args["orderby"] == 2:
            orderby = [Item.name]

    items = (
        ShoppinglistItems.query.filter(ShoppinglistItems.shoppinglist_id == id)
        .join(ShoppinglistItems.item)
        .order_by(*orderby, Item.name)
        .all()
    )
    return jsonify([e.obj_to_item_dict() for e in items])


@shoppinglist.route("/<int:id>/recent-items", methods=["GET"])
@jwt_required()
@validate_args(GetRecentItems)
def getRecentItems(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    items = History.get_recent(id, args["limit"])
    return jsonify(
        [e.item.obj_to_dict() | {"description": e.description} for e in items]
    )


def getSuggestionsBasedOnLastAddedItems(id, item_count):
    suggestions = []

    # subquery for item ids which are on the shoppinglist
    subquery = (
        db.session.query(ShoppinglistItems.item_id)
        .filter(ShoppinglistItems.shoppinglist_id == id)
        .subquery()
    )

    # suggestion based on recently added items
    ten_minutes_back = datetime.now() - timedelta(minutes=10)
    recently_added = (
        History.query.filter(
            History.shoppinglist_id == id,
            History.status == Status.ADDED,
            History.created_at > ten_minutes_back,
        )
        .order_by(History.created_at.desc())
        .limit(3)
    )

    for recent in recently_added:
        assocs = (
            Association.query.filter(
                Association.antecedent_id == recent.id,
                Association.consequent_id.notin_(subquery),
            )
            .order_by(Association.lift.desc())
            .limit(item_count)
        )
        for rule in assocs:
            suggestions.append(rule.consequent)
            item_count -= 1

    return suggestions


def getSuggestionsBasedOnFrequency(id, item_count):
    suggestions = []

    # subquery for item ids which are on the shoppinglist
    subquery = (
        db.session.query(ShoppinglistItems.item_id)
        .filter(ShoppinglistItems.shoppinglist_id == id)
        .subquery()
    )

    # suggestion based on overall frequency
    if item_count > 0:
        suggestions = (
            Item.query.filter(Item.id.notin_(subquery))
            .order_by(Item.support.desc(), Item.name)
            .limit(item_count)
        )
    return suggestions


@shoppinglist.route("/<int:id>/suggested-items", methods=["GET"])
@jwt_required()
def getSuggestedItems(id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item_suggestion_count = 9
    suggestions = []

    suggestions += getSuggestionsBasedOnLastAddedItems(id, item_suggestion_count)
    suggestions += getSuggestionsBasedOnFrequency(
        id, item_suggestion_count - len(suggestions)
    )

    return jsonify([item.obj_to_dict() for item in suggestions])


@shoppinglist.route("/<int:id>/add-item-by-name", methods=["POST"])
@jwt_required()
@validate_args(AddItemByName)
def addShoppinglistItemByName(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item = Item.find_by_name(shoppinglist.household_id, args["name"])
    if not item:
        item = Item.create_by_name(shoppinglist.household_id, args["name"])

    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        description = args["description"] if "description" in args else ""
        con = ShoppinglistItems(description=description)
        con.created_by = current_user.id
        con.item = item
        con.shoppinglist = shoppinglist
        con.save()

        History.create_added(shoppinglist, item, description)

        socketio.emit(
            "shoppinglist_item:add",
            {
                "item": con.obj_to_item_dict(),
                "shoppinglist": shoppinglist.obj_to_dict(),
            },
            to=shoppinglist.household_id,
        )

    return jsonify(item.obj_to_dict())


@shoppinglist.route("/<int:id>/item", methods=["DELETE"])
@jwt_required()
@validate_args(RemoveItem)
def removeShoppinglistItem(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    con = removeShoppinglistItem(
        shoppinglist,
        args["item_id"],
        args["removed_at"] if "removed_at" in args else None,
    )
    if con:
        socketio.emit(
            "shoppinglist_item:remove",
            {
                "item": con.obj_to_item_dict(),
                "shoppinglist": shoppinglist.obj_to_dict(),
            },
            to=shoppinglist.household_id,
        )

    return jsonify({"msg": "DONE"})


@shoppinglist.route("/<int:id>/items", methods=["DELETE"])
@jwt_required()
@validate_args(RemoveItems)
def removeShoppinglistItems(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    for arg in args["items"]:
        con = removeShoppinglistItem(
            shoppinglist,
            arg["item_id"],
            arg["removed_at"] if "removed_at" in arg else None,
        )
        if con:
            socketio.emit(
                "shoppinglist_item:remove",
                {
                    "item": con.obj_to_item_dict(),
                    "shoppinglist": shoppinglist.obj_to_dict(),
                },
                to=shoppinglist.household_id,
            )

    return jsonify({"msg": "DONE"})


def removeShoppinglistItem(
    shoppinglist: Shoppinglist, item_id: int, removed_at: int = None
) -> ShoppinglistItems:
    item = Item.find_by_id(item_id)
    if not item:
        return None
    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        return None
    description = con.description
    con.delete()

    removed_at_datetime = None
    if removed_at:
        removed_at_datetime = datetime.fromtimestamp(removed_at / 1000, timezone.utc)

    History.create_dropped(shoppinglist, item, description, removed_at_datetime)
    return con


@shoppinglist.route("/<int:id>/recipeitems", methods=["POST"])
@jwt_required()
@validate_args(AddRecipeItems)
def addRecipeItems(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    try:
        for recipeItem in args["items"]:
            item = Item.find_by_id(recipeItem["id"])
            if item:
                description = recipeItem["description"]
                con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
                if con:
                    # merge descriptions
                    con.description = description_merger.merge(
                        con.description, description
                    )
                    db.session.add(con)
                else:
                    con = ShoppinglistItems(description=description)
                    con.created_by = current_user.id
                    con.item = item
                    con.shoppinglist = shoppinglist
                    db.session.add(con)

                db.session.add(
                    History.create_added_without_save(shoppinglist, item, description)
                )

                socketio.emit(
                    "shoppinglist_item:add",
                    {
                        "item": con.obj_to_item_dict(),
                        "shoppinglist": shoppinglist.obj_to_dict(),
                    },
                    to=shoppinglist.household_id,
                )

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e

    return jsonify(item.obj_to_dict())
