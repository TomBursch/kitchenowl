from flask_jwt_extended import current_user
from flask_socketio import emit
from app.controller.shoppinglist.shoppinglist_controller import removeShoppinglistItem
from app.errors import NotFoundRequest

from app.helpers import socket_jwt_required, validate_socket_args
from app.models import Shoppinglist, Item, ShoppinglistItems, History
from app import socketio
from .schemas import shoppinglist_item_add, shoppinglist_item_remove


@socketio.on('shoppinglist_item:add')
@socket_jwt_required()
@validate_socket_args(shoppinglist_item_add)
def on_add(args):
    shoppinglist = Shoppinglist.find_by_id(args['shoppinglist_id'])
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item = Item.find_by_name(shoppinglist.household_id, args['name'])
    if not item:
        item = Item.create_by_name(shoppinglist.household_id, args['name'])

    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        description = args['description'] if 'description' in args else ''
        con = ShoppinglistItems(description=description)
        con.created_by = current_user.id
        con.item = item
        con.shoppinglist = shoppinglist
        con.save()

        History.create_added(shoppinglist, item, description)

        emit("shoppinglist_item:add", {
            "item": con.obj_to_item_dict(),
            "shoppinglist": shoppinglist.obj_to_dict()
        }, to=shoppinglist.household_id)


@socketio.on('shoppinglist_item:remove')
@socket_jwt_required()
@validate_socket_args(shoppinglist_item_remove)
def on_remove(args):
    shoppinglist = Shoppinglist.find_by_id(args['shoppinglist_id'])
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    con = removeShoppinglistItem(shoppinglist, args['item_id'])
    if con:
        emit('shoppinglist_item:remove', {
            "item": con.obj_to_item_dict(),
            "shoppinglist": shoppinglist.obj_to_dict()
        }, to=shoppinglist.household_id)
