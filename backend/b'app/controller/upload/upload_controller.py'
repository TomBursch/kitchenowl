from app.config import ALLOWED_FILE_EXTENSIONS, UPLOAD_FOLDER
from flask import jsonify, Blueprint, send_from_directory, request
from flask_jwt_extended import jwt_required
from werkzeug.utils import secure_filename
import os
import uuid

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


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_FILE_EXTENSIONS
