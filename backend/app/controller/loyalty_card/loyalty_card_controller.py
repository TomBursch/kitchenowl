from app.errors import NotFoundRequest
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.helpers import validate_args, authorize_household
from app.models import LoyaltyCard
from .schemas import AddLoyaltyCard, UpdateLoyaltyCard

loyaltyCard = Blueprint("loyalty_card", __name__)
loyaltyCardHousehold = Blueprint("loyalty_card", __name__)


@loyaltyCardHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllLoyaltyCards(household_id):
    return jsonify(
        [e.obj_to_dict() for e in LoyaltyCard.find_by_household(household_id)]
    )


@loyaltyCard.route("/<int:id>", methods=["GET"])
@jwt_required()
def getLoyaltyCardById(id):
    loyalty_card = LoyaltyCard.find_by_id(id)
    if not loyalty_card:
        raise NotFoundRequest()
    loyalty_card.checkAuthorized()
    return jsonify(loyalty_card.obj_to_full_dict())


@loyaltyCardHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddLoyaltyCard)
def addLoyaltyCard(args, household_id):
    loyalty_card = LoyaltyCard()
    loyalty_card.name = args["name"]
    loyalty_card.household_id = household_id
    if "barcode_type" in args:
        loyalty_card.barcode_type = args["barcode_type"]
    if "barcode_data" in args:
        loyalty_card.barcode_data = args["barcode_data"]
    if "description" in args:
        loyalty_card.description = args["description"]
    if "color" in args:
        loyalty_card.color = args["color"]
    loyalty_card.save()
    return jsonify(loyalty_card.obj_to_dict())


@loyaltyCard.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateLoyaltyCard)
def updateLoyaltyCard(args, id):
    loyalty_card = LoyaltyCard.find_by_id(id)
    if not loyalty_card:
        raise NotFoundRequest()
    loyalty_card.checkAuthorized()

    if "name" in args:
        loyalty_card.name = args["name"]
    if "barcode_type" in args:
        loyalty_card.barcode_type = args["barcode_type"]
    if "barcode_data" in args:
        loyalty_card.barcode_data = args["barcode_data"]
    if "description" in args:
        loyalty_card.description = args["description"]
    if "color" in args:
        loyalty_card.color = args["color"]

    loyalty_card.save()
    return jsonify(loyalty_card.obj_to_dict())


@loyaltyCard.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteLoyaltyCardById(id):
    loyalty_card = LoyaltyCard.find_by_id(id)
    if not loyalty_card:
        raise NotFoundRequest()
    loyalty_card.checkAuthorized()

    loyalty_card.delete()
    return jsonify({"msg": "DONE"})

