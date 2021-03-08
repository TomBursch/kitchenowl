from app.helpers import validate_args
import json
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from app.models import Item
from .schemas import SearchByNameRequest


@app.route('/item', methods=['GET'])
@jwt_required()
def getAllItems():
    return jsonify([e.obj_to_dict() for e in Item.all()])


@app.route('/item/<id>', methods=['DELETE'])
@jwt_required()
def deleteItemById(id):
    Item.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@app.route('/item/search', methods=['GET'])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchItemByName(args):
    return jsonify([e.obj_to_dict() for e in Item.search_name(args['query'])])
