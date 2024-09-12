import os
import shutil
import uuid
import requests
import blurhash
from PIL import Image
from app.util.filename_validator import allowed_file
from app.config import UPLOAD_FOLDER
from app.models import File
from flask_jwt_extended import current_user
from werkzeug.utils import secure_filename


def file_has_access_or_download(newPhoto: str, oldPhoto: str | None = None) -> str | None:
    """
    Downloads the file if the url is an external URL or checks if the user has access to the file on this server
    If the user has no access oldPhoto is returned
    """
    if newPhoto is not None and "/" in newPhoto:
        from mimetypes import guess_extension

        resp = requests.get(newPhoto)
        ext = guess_extension(resp.headers["content-type"])
        if ext and allowed_file("file" + ext):
            filename = secure_filename(str(uuid.uuid4()) + ext)
            with open(os.path.join(UPLOAD_FOLDER, filename), "wb") as o:
                o.write(resp.content)
            blur = None
            try:
                with Image.open(os.path.join(UPLOAD_FOLDER, filename)) as image:
                    image.thumbnail((100, 100))
                    blur = blurhash.encode(image, x_components=4, y_components=3)
            except FileNotFoundError:
                return None
            except Exception:
                pass
            File(filename=filename, blur_hash=blur, created_by=current_user.id).save()
            return filename
    elif newPhoto is not None:
        if not newPhoto:
            return None
        f = File.find(newPhoto)
        if f and f.isUnused() and (f.created_by == current_user.id or current_user.admin):
            return f.filename
        elif f:
            f.checkAuthorized()
            filename = secure_filename(str(uuid.uuid4()) + "." + f.filename.split(".")[-1])
            shutil.copyfile(os.path.join(UPLOAD_FOLDER, f.filename), os.path.join(UPLOAD_FOLDER, filename))
            File(filename=filename, blur_hash=f.blur_hash, created_by=current_user.id).save()
            return filename

    return oldPhoto
