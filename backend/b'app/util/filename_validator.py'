from app.config import ALLOWED_FILE_EXTENSIONS


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_FILE_EXTENSIONS
