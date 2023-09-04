import os
from app.config import UPLOAD_FOLDER, db, app
from app.models import File
import blurhash
from PIL import Image


def recalculateBlurhashes(updateAll: bool = False) -> int:
    files = File.all() if updateAll else File.query.filter(File.blur_hash == None).all()
    for file in files:
        try:
            with Image.open(os.path.join(UPLOAD_FOLDER, file.filename)) as image:
                image.thumbnail((100, 100))
                file.blur_hash = blurhash.encode(
                    image, x_components=4, y_components=3)
            db.session.add(file)
        except FileNotFoundError:
            db.session.delete(file)
        except Exception:
            pass
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise e

    app.logger.info(f"Updated {len(files)} files")
    return len(files)
