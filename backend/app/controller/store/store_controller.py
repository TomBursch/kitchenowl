from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app.models import Store
from .schemas import AddStore, UpdateStore

store = Blueprint("store", __name__)
storeHousehold = Blueprint("store", __name__)


@storeHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllStores(household_id):
    return jsonify(
        [e.obj_to_dict() for e in Store.all_from_household_by_name(household_id)]
    )


@store.route("/<int:id>", methods=["GET"])
@jwt_required()
def getStore(id):
    store = Store.find_by_id(id)
    if not store:
        raise NotFoundRequest()
    store.checkAuthorized()
    return jsonify(store.obj_to_dict())


@storeHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddStore)
def addStore(args, household_id):
    store = Store()
    store.name = args["name"]
    store.household_id = household_id
    store.save()
    return jsonify(store.obj_to_dict())


@store.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateStore)
def updateStore(args, id):
    store = Store.find_by_id(id)
    if not store:
        raise NotFoundRequest()
    store.checkAuthorized()

    if "name" in args:
        store.name = args["name"]

    store.save()

    if "merge_store_id" in args and args["merge_store_id"] != id:
        mergeStore = Store.find_by_id(args["merge_store_id"])
        if mergeStore:
            store.merge(mergeStore)

    return jsonify(store.obj_to_dict())


@store.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteStoreById(id):
    store = Store.find_by_id(id)
    if not store:
        raise NotFoundRequest()
    store.checkAuthorized()
    store.delete()
    return jsonify({"msg": "DONE"})
