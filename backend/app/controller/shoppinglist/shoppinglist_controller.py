from app.models import ShoppinglistItems
import json
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app, db
from app.models import Item, Shoppinglist, History, Status, Association
from app.helpers import validate_args
from .schemas import (RemoveItem, UpdateDescription,
                      AddItemByName, CreateList, AddRecipeItems)
from app.errors import InvalidUsage, NotFoundRequest
from datetime import datetime, timedelta


@app.before_first_request
def before_first_request():
    # Add default shoppinglist
    if(not Shoppinglist.find_by_id(1)):
        sl = Shoppinglist(
            name='Default'
        )
        sl.save()


@app.route('/shoppinglist/<id>/item/<item_id>', methods=['GET'])
@jwt_required()
def getShoppingListItem(id, item_id):
    item = Item.find_by_id(item_id)
    if not item:
        raise NotFoundRequest()
    return jsonify(item.obj_to_dict())


@app.route('/shoppinglist/<id>/item/<item_id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateDescription)
def updateItemDescription(args, id, item_id):
    con = ShoppinglistItems.find_by_ids(id, item_id)
    if not con:
        raise NotFoundRequest()

    con.description = args['description'] or ''
    con.save()
    return jsonify(con.obj_to_item_dict())


@app.route('/shoppinglist/<id>/items', methods=['GET'])
@jwt_required()
def getAllShoppingListItems(id):
    items = ShoppinglistItems.query.filter(
        ShoppinglistItems.shoppinglist_id == id).join(
        ShoppinglistItems.item).order_by(
        Item.name).all()
    return jsonify([e.obj_to_item_dict() for e in items])


@app.route('/shoppinglist/<id>/recent-items', methods=['GET'])
@jwt_required()
def getRecentItems(id):
    items = History.get_recent(id)
    return jsonify([e.item.obj_to_dict() for e in items])


def getSuggestionsBasedOnLastAddedItems(id, item_count):
    suggestions = []

    # subquery for item ids which are on the shoppinglist
    subquery = db.session.query(ShoppinglistItems.item_id).filter(
        ShoppinglistItems.shoppinglist_id == id).subquery()

    # suggestion based on recently added items
    ten_minutes_back = datetime.now() - timedelta(minutes=10)
    recently_added = History.query.filter(
        History.shoppinglist_id == id,
        History.status == Status.ADDED,
        History.created_at > ten_minutes_back).order_by(
        History.created_at.desc()).limit(3)

    for recent in recently_added:
        assocs = Association.query.filter(
            Association.antecedent_id == recent.id,
            Association.consequent_id.notin_(subquery)).order_by(
            Association.lift.desc()).limit(item_count)
        for rule in assocs:
            suggestions.append(rule.consequent)
            item_count -= 1

    return suggestions


def getSuggestionsBasedOnFrequency(id, item_count):
    suggestions = []

    # subquery for item ids which are on the shoppinglist
    subquery = db.session.query(ShoppinglistItems.item_id).filter(
        ShoppinglistItems.shoppinglist_id == id).subquery()

    # suggestion based on overall frequency
    if item_count > 0:
        suggestions = Item.query.filter(Item.id.notin_(subquery)).order_by(
            Item.support.desc(), Item.name).limit(item_count)
    return suggestions


@app.route('/shoppinglist/<id>/suggested-items', methods=['GET'])
@jwt_required()
def getSuggestedItems(id):
    item_suggestion_count = 9
    suggestions = []

    suggestions += getSuggestionsBasedOnLastAddedItems(
        id, item_suggestion_count)
    suggestions += getSuggestionsBasedOnFrequency(
        id, item_suggestion_count - len(suggestions))

    return jsonify([item.obj_to_dict() for item in suggestions])


@app.route('/shoppinglist/<id>/add-item-by-name', methods=['POST'])
@jwt_required()
@validate_args(AddItemByName)
def addShoppinglistItemByName(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    item = Item.find_by_name(args['name'])
    if not item:
        item = Item.create_by_name(args['name'])

    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        description = args['description'] if 'description' in args else ''
        con = ShoppinglistItems(description=description)
        con.item = item
        con.shoppinglist = shoppinglist
        con.save()

    History.create_added(shoppinglist, item)

    return jsonify(item.obj_to_dict())


@app.route('/shoppinglist/<id>/item', methods=['DELETE'])
@jwt_required()
@validate_args(RemoveItem)
def removeShoppinglistItem(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    item = Item.find_by_id(args['item_id'])
    if not item:
        item = Item.find_by_name(args['name'])
    if not item:
        raise NotFoundRequest()
    con = ShoppinglistItems.find_by_ids(id, args['item_id'])
    con.delete()

    History.create_dropped(shoppinglist, item)

    return jsonify({'msg': "DONE"})


@app.route('/shoppinglist', methods=['POST'])
@jwt_required()
@validate_args(CreateList)
def createList(args):
    return jsonify(Shoppinglist.create(
        args['name']).save().obj_to_dict())


@app.route('/shoppinglist/<id>/recipeitems', methods=['POST'])
@jwt_required()
@validate_args(AddRecipeItems)
def addRecipeItems(args, id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()

    for recipeItem in args['items']:
        item = Item.find_by_id(recipeItem['id'])
        if item:
            description = recipeItem['description']
            con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
            if con:
                con.description = \
                    description if not con.description else con.description + \
                    ', ' + description
                con.save()
            else:
                con = ShoppinglistItems(description=description)
                con.item = item
                con.shoppinglist = shoppinglist
                con.save()

            History.create_added(shoppinglist, item)

    shoppinglist.save()
    return jsonify(item.obj_to_dict())

# @app.route('/shoppinglist/<id>/item', methods=['POST'])
# @jwt_required()
# @validate_args(UpdateDescription)
# def updateDescription(args, id):
#     item = ShoppinglistItem.find_by_ids(id, args['item_id'])
#     if (not item):
#         raise Exception()
#     item.desciption = args['description']
#     item.save()
#     return jsonify(item.obj_to_dict())


@app.route('/shoppinglist/<id>', methods=['GET'])
@jwt_required()
def getShoppinglist(id):
    shoppinglist = Shoppinglist.find_by_id(id)
    if not shoppinglist:
        raise NotFoundRequest()
    return jsonify(shoppinglist.obj_to_dict())
