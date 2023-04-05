from app import app
from app.models import Household
from app.service.export_import import importLanguage


if __name__ == "__main__":
    with app.app_context():
        for household in Household.all():
            if household.language:
                importLanguage(household.id,
                               household.language, bulkSave=True)
