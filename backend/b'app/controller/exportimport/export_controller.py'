from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.models import Item, Recipe

export = Blueprint('export', __name__)


@export.route('', methods=['GET'])
@jwt_required()
def getExportAll():
    return jsonify({
        "items": [e.obj_to_export_dict() for e in Item.all()],
        "recipes": [e.obj_to_export_dict() for e in Recipe.all()]
    })


@export.route('/items', methods=['GET'])
@jwt_required()
def getExportItems():
    return jsonify({"items": [e.obj_to_export_dict() for e in Item.all()]})


@export.route('/recipes', methods=['GET'])
@jwt_required()
def getExportRecipes():
    return jsonify({"recipes": [e.obj_to_export_dict() for e in Recipe.all()]})
