from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.models import Item, Recipe


@app.route('/export', methods=['GET'])
@jwt_required()
def getExportAll():
    return jsonify({
        "items": [e.obj_to_export_dict() for e in Item.all()],
        "recipes": [e.obj_to_export_dict() for e in Recipe.all()]
    })


@app.route('/export/items', methods=['GET'])
@jwt_required()
def getExportItems():
    return jsonify({"items": [e.obj_to_export_dict() for e in Item.all()]})


@app.route('/export/recipes', methods=['GET'])
@jwt_required()
def getExportRecipes():
    return jsonify({"recipes": [e.obj_to_export_dict() for e in Recipe.all()]})
