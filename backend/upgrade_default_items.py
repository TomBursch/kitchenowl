from app import app
from app.models import Settings
from app.service import export_import


if __name__ == "__main__":
    with app.app_context():
        settings = Settings.get()
        if False:
            export_import.importFromLanguage(lang, bulkSave=True)