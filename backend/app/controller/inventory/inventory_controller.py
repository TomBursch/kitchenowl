from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from app import db
from app.models import (
    Item,
    Inventory,
    InventoryItems,
)
from app.helpers import validate_args, authorize_household
from .schemas import (
    GetInventories,
    RemoveItem,
    UpdateDescription,
    AddItemByName,
    CreateList,
    AddShoppinglistItems,
    GetItems,
    UpdateList,
    RemoveItems,
)
from app.errors import NotFoundRequest, InvalidUsage
import app.util.description_merger as description_merger
from app import socketio


inventory = Blueprint("inventory", __name__)
inventoryHousehold = Blueprint("inventory", __name__)


@inventoryHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(CreateList)
def createInventory(args, household_id):
    inventory = Inventory(name=args["name"], household_id=household_id)
    inventory.save()
    inventory_dict = inventory.obj_to_dict()
    socketio.emit(
        "inventory:add",
        {"inventory": inventory_dict},
        to="household/" + str(household_id),
    )
    return jsonify(inventory_dict)


@inventoryHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetInventories)
def getInventories(args, household_id):
    inventories = Inventory.all_from_household(household_id)

    orderby = [Item.name]
    if "orderby" in args and args["orderby"] == 1:
        orderby = [Item.ordering == 0, Item.ordering]

    items = {}
    for inventory in inventories:
        items[inventory.id] = (
            InventoryItems.query.filter(InventoryItems.inventory_id == inventory.id)
            .join(InventoryItems.item)
            .order_by(*orderby, Item.name)
            .all()
        )

    return jsonify(
        [
            inventory.obj_to_dict()
            | {
                "recentItems": [],
                "items": [e.obj_to_item_dict() for e in items[inventory.id]],
            }
            for inventory in inventories
        ]
    )


@inventory.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateList)
def updateInventory(args, id):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    if "name" in args:
        inventory.name = args["name"]

    inventory.save()
    return jsonify(inventory.obj_to_dict())


@inventory.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteInventory(id):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()
    if inventory.isDefault():
        raise InvalidUsage()
    inventory.delete()
    socketio.emit(
        "inventory:delete",
        {"inventory": inventory.obj_to_dict()},
        to="household/" + str(inventory.household_id),
    )

    return jsonify({"msg": "DONE"})


@inventory.route("/<int:id>/item/<int:item_id>", methods=["POST", "PUT"])
@jwt_required()
@validate_args(UpdateDescription)
def updateItemDescription(args, id: int, item_id: int):
    con = InventoryItems.find_by_ids(id, item_id)
    if not con:
        inventory = Inventory.find_by_id(id)
        item = Item.find_by_id(item_id)
        if not item or not inventory:
            raise NotFoundRequest()
        if inventory.household_id != item.household_id:
            raise InvalidUsage()
        con = InventoryItems()
        con.inventory = inventory
        con.item = item
        con.created_by = current_user.id
    con.inventory.checkAuthorized()

    con.description = args["description"] or ""
    con.save()
    socketio.emit(
        "inventory_item:add",
        {
            "item": con.obj_to_item_dict(),
            "inventory": con.inventory.obj_to_dict(),
        },
        to="household/" + str(con.inventory.household_id),
    )
    return jsonify(con.obj_to_item_dict())


@inventory.route("/<int:id>/items", methods=["GET"])
@jwt_required()
@validate_args(GetItems)
def getAllInventoryItems(args, id):
    """
    Deprecated in favor of including it directly in the shopping list
    """
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    orderby = [Item.name]
    if "orderby" in args:
        if args["orderby"] == 1:
            orderby = [Item.ordering == 0, Item.ordering]
        elif args["orderby"] == 2:
            orderby = [Item.name]

    items = (
        InventoryItems.query.filter(InventoryItems.inventory_id == id)
        .join(InventoryItems.item)
        .order_by(*orderby, Item.name)
        .all()
    )
    return jsonify([e.obj_to_item_dict() for e in items])


@inventory.route("/<int:id>/add-item-by-name", methods=["POST"])
@jwt_required()
@validate_args(AddItemByName)
def addInventoryItemByName(args, id):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    item = Item.find_by_name(inventory.household_id, args["name"])
    if not item:
        item = Item.create_by_name(inventory.household_id, args["name"])

    con = InventoryItems.find_by_ids(inventory.id, item.id)
    if not con:
        description = args["description"] if "description" in args else ""
        con = InventoryItems(description=description)
        con.created_by = current_user.id
        con.item = item
        con.inventory = inventory
        con.save()

        socketio.emit(
            "inventory_item:add",
            {
                "item": con.obj_to_item_dict(),
                "inventory": inventory.obj_to_dict(),
            },
            to="household/" + str(inventory.household_id),
        )

    return jsonify(item.obj_to_dict())


@inventory.route("/<int:id>/item", methods=["DELETE"])
@jwt_required()
@validate_args(RemoveItem)
def removeInventoryItem(args, id: int):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    con = removeInventoryItemFunc(
        inventory,
        args["item_id"],
        args["removed_at"] if "removed_at" in args else None,
    )
    if con:
        socketio.emit(
            "inventory_item:remove",
            {
                "item": con.obj_to_item_dict(),
                "inventory": inventory.obj_to_dict(),
            },
            to="household/" + str(inventory.household_id),
        )

    return jsonify({"msg": "DONE"})


@inventory.route("/<int:id>/items", methods=["DELETE"])
@jwt_required()
@validate_args(RemoveItems)
def removeInventoryItems(args, id: int):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    for arg in args["items"]:
        con = removeInventoryItemFunc(
            inventory,
            arg["item_id"],
            arg["removed_at"] if "removed_at" in arg else None,
        )
        if con:
            socketio.emit(
                "inventory_item:remove",
                {
                    "item": con.obj_to_item_dict(),
                    "inventory": inventory.obj_to_dict(),
                },
                to="household/" + str(inventory.household_id),
            )

    return jsonify({"msg": "DONE"})


def removeInventoryItemFunc(
    inventory: Inventory, item_id: int, removed_at: int | None = None
) -> InventoryItems | None:
    item = Item.find_by_id(item_id)
    if not item:
        return None
    con = InventoryItems.find_by_ids(inventory.id, item.id)
    if not con:
        return None
    con.delete()

    return con


@inventory.route("/<int:id>/shoppinglistitems", methods=["POST"])
@jwt_required()
@validate_args(AddShoppinglistItems)
def addRecipeItems(args, id):
    inventory = Inventory.find_by_id(id)
    if not inventory:
        raise NotFoundRequest()
    inventory.checkAuthorized()

    try:
        for recipeItem in args["items"]:
            item = Item.find_by_id(recipeItem["id"])
            if item:
                item.checkAuthorized()
                description = recipeItem["description"]
                con = InventoryItems.find_by_ids(inventory.id, item.id)
                if con:
                    # merge descriptions
                    con.description = description_merger.merge(
                        con.description, description
                    )
                    db.session.add(con)
                else:
                    con = InventoryItems(description=description)
                    con.created_by = current_user.id
                    con.item = item
                    con.inventory = inventory
                    db.session.add(con)

                socketio.emit(
                    "inventory_item:add",
                    {
                        "item": con.obj_to_item_dict(),
                        "inventory": inventory.obj_to_dict(),
                    },
                    to="household/" + str(inventory.household_id),
                )

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e

    return jsonify({"msg": "DONE"})
