import os
import uuid

from flask import jsonify, Blueprint, send_from_directory, request
from flask_jwt_extended import current_user, jwt_required
from werkzeug.utils import secure_filename
import blurhash
from PIL import Image

from app.config import UPLOAD_FOLDER
from app.errors import NotFoundRequest
from app.models import File
from app.util.filename_validator import allowed_file

upload = Blueprint("upload", __name__)


@upload.route("", methods=["POST"])
@jwt_required()
def upload_file():
    if "file" not in request.files:
        return jsonify({"msg": "missing file"})

    file = request.files["file"]
    # If the user does not select a file, the browser submits an
    # empty file without a filename.
    if file.filename == "":
        return jsonify({"msg": "missing filename"})

    if file and file.filename and allowed_file(file.filename):
        filename = secure_filename(
            str(uuid.uuid4()) + "." + file.filename.rsplit(".", 1)[1].lower()
        )
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        blur = None
        try:
            with Image.open(os.path.join(UPLOAD_FOLDER, filename)) as image:
                image.thumbnail((100, 100))
                blur = blurhash.encode(image, x_components=4, y_components=3)
        except FileNotFoundError:
            return None
        except Exception:
            pass
        f = File(filename=filename, blur_hash=blur, created_by=current_user.id).save()
        return jsonify(f.obj_to_dict())

    raise Exception("Invalid usage.")


@upload.route("<filename>", methods=["GET"])
@jwt_required(optional=True)
def download_file(filename):
    filename = secure_filename(filename)
    f: File | None = File.query.filter(File.filename == filename).first()

    if not f:
        raise NotFoundRequest()

    f.checkAuthorized()

    return send_from_directory(UPLOAD_FOLDER, filename)
