from app.models import ShoppinglistItems
import json
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app, db
from app.models import Item, Shoppinglist
from app.helpers import validate_args
from .schemas import RemoveItem, UpdateDescription, AddItemByName, CreateList, AddRecipeItems
from app.errors import InvalidUsage, NotFoundRequest


@app.before_first_request
def before_first_request():
    # Add default shoppinglist
    if(not Shoppinglist.find_by_id(1)):
        sl = Shoppinglist(
            name='Default'
        )
        sl.save()


@app.route('/shoppinglist/<id>/items', methods=['GET'])
@jwt_required()
def getAllShoppingListItems(id):
    return jsonify([e.obj_to_item_dict() for e in Shoppinglist.find_by_id(id).items])


@app.route('/shoppinglist/<id>/recent-items', methods=['GET'])
@jwt_required()
def getRecentItems(id):
    sq = db.session.query(ShoppinglistItems.item_id).filter(
        ShoppinglistItems.shoppinglist_id == id).subquery()
    q = Item.query.filter(Item.id.notin_(sq)).order_by(
        Item.updated_at).limit(9)
    return jsonify([e.obj_to_dict() for e in q])


@app.route('/shoppinglist/<id>/item', methods=['POST'])
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
                con.description = description if not con.description else con.description + \
                    ', ' + description
                con.save()
            else:
                con = ShoppinglistItems(description=description)
                con.item = item
                shoppinglist.items.append(con)

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
