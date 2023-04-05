from flask import jsonify, Blueprint
from app.config import BACKEND_VERSION, MIN_FRONTEND_VERSION
from app.models import Settings
from app.config import SUPPORTED_LANGUAGES

health = Blueprint('health', __name__)


@health.route('', methods=['GET'])
def get_health():
    info = {
        'msg': "OK",
        'version': BACKEND_VERSION,
        'min_frontend_version': MIN_FRONTEND_VERSION,
    }
    return jsonify(info)

@health.route('/supported-languages', methods=['GET'])
def getSupportedLanguages():
    return jsonify(SUPPORTED_LANGUAGES)