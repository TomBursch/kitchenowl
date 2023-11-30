from tqdm import tqdm
from app.errors import NotFoundRequest
from app.models import Household
from app.service.import_language import importLanguage


if __name__ == "__main__":
    for household in tqdm(Household.query.filter(Household.language != None).all(), desc="Upgrading households..."):
        try:
            importLanguage(household.id, household.language, bulkSave=True)
        except NotFoundRequest:
            pass
