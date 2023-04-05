from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.helpers import authorize_household
from app.models import Item, Recipe

export = Blueprint('export', __name__)


@export.route('', methods=['GET'])
@jwt_required()
@authorize_household()
def getExportAll(household_id):
    return jsonify({
        "items": [e.obj_to_export_dict() for e in Item.all_from_household_by_name(household_id)],
        "recipes": [e.obj_to_export_dict() for e in Recipe.all_from_household_by_name(household_id)]
    })


@export.route('/items', methods=['GET'])
@jwt_required()
@authorize_household()
def getExportItems(household_id):
    return jsonify({"items": [e.obj_to_export_dict() for e in Item.all_from_household_by_name(household_id)]})


@export.route('/recipes', methods=['GET'])
@jwt_required()
@authorize_household()
def getExportRecipes(household_id):
    return jsonify({"recipes": [e.obj_to_export_dict() for e in Recipe.all_from_household_by_name(household_id)]})
