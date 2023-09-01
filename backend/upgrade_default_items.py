from app import app
from app.errors import NotFoundRequest
from app.models import Household
from app.service.import_language import importLanguage


if __name__ == "__main__":
    with app.app_context():
        for household in Household.query.filter(Household.language != None).all():
            try:
                importLanguage(household.id, household.language, bulkSave=True)
            except NotFoundRequest:
                pass
