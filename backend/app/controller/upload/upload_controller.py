import os
import uuid

from flask import jsonify, Blueprint, send_from_directory, request
from flask_jwt_extended import jwt_required
from werkzeug.utils import secure_filename

from app.config import UPLOAD_FOLDER
from app.util.filename_validator import allowed_file

upload = Blueprint('upload', __name__)


@upload.route('', methods=['POST'])
@jwt_required()
def upload_file():
    if 'file' not in request.files:
        return jsonify({'msg': 'missing file'})

    file = request.files['file']
    # If the user does not select a file, the browser submits an
    # empty file without a filename.
    if file.filename == '':
        return jsonify({'msg': 'missing filename'})

    if file and allowed_file(file.filename):
        filename = secure_filename(str(uuid.uuid4()) + '.' +
                                   file.filename.rsplit('.', 1)[1].lower())
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        return jsonify({'name': filename})

    raise Exception("Invalid usage.")


@upload.route('<name>', methods=['GET'])
@jwt_required()
def download_file(name):
    return send_from_directory(UPLOAD_FOLDER, name)
