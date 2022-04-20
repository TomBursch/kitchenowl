from app.service.export_import import importFromDict, importFromLanguage
from .schemas import ImportSchema
from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required
from app.config import SUPPORTED_LANGUAGES

importBP = Blueprint('import', __name__)


@importBP.route('', methods=['POST'])
@jwt_required()
@validate_args(ImportSchema)
def importData(args):
    importFromDict(args)
    return jsonify({'msg': 'DONE'})


@importBP.route('/<lang>', methods=['GET'])
@jwt_required()
def importLang(lang):
    importFromLanguage(lang)
    return jsonify({'msg': 'DONE'})


@importBP.route('/supported-languages', methods=['GET'])
def getSupportedLanguages():
    return jsonify(SUPPORTED_LANGUAGES)
