import os
import uuid
import requests
from app.util.filename_validator import allowed_file
from app.config import UPLOAD_FOLDER
from app.models import File
from flask_jwt_extended import current_user
from werkzeug.utils import secure_filename


def file_has_access_or_download(newPhoto: str, oldPhoto: str = None) -> str:
    """
    Downloads the file if the url is an external URL or checks if the user has access to the file on this server
    If the user has no access oldPhoto is returned
    """
    if newPhoto is not None and '/' in newPhoto:
        from mimetypes import guess_extension
        resp = requests.get(newPhoto)
        ext = guess_extension(resp.headers['content-type'])
        if allowed_file('file' + ext):
            filename = secure_filename(str(uuid.uuid4()) + ext)
            File(filename=filename, created_by=current_user.id).save()
            with open(os.path.join(UPLOAD_FOLDER, filename), "wb") as o:
                o.write(resp.content)
            return filename
    elif newPhoto is not None:
        f = File.find(newPhoto)
        if f and (f.created_by == current_user.id or current_user.admin):
            return f.filename
    return oldPhoto
