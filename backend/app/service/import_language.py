import time
from app.config import app, APP_DIR, SUPPORTED_LANGUAGES, db
from os.path import exists
import json

from app.errors import NotFoundRequest
from app.models import Item, Category


def importLanguage(household_id, lang, bulkSave=False):
    file_path = f'{APP_DIR}/../templates/l10n/{lang}.json'
    if lang not in SUPPORTED_LANGUAGES or not exists(file_path):
        raise NotFoundRequest('Language code not supported')
    with open(file_path, 'r') as f:
        data = json.load(f)
    with open(f'{APP_DIR}/../templates/attributes.json', 'r') as f:
        attributes = json.load(f)

    t0 = time.time()
    models: list[Item] = []
    for key, name in data["items"].items():
        item = Item.find_by_default_key(
            household_id, key) or Item.find_by_name(household_id, name)
        if not item:
            # slow but needed to filter out duplicate names
            if bulkSave and any(i.name == name for i in models):
                continue
            item = Item()
            item.name = name.strip()
            item.household_id = household_id
            item.default = True
            item.default_key = key

        if not item.default_key:  # migrate to new system
            item.default_key = key

        if item.default:
            item.name = name.strip()

            if key in attributes["items"] and "icon" in attributes["items"][key]:
                item.icon = attributes["items"][key]["icon"]

            # Category not already set for existing item and category set for template and category translation exist for language
            if key in attributes["items"] and "category" in attributes["items"][key] and attributes["items"][key]["category"] in data["categories"]:
                category_key = attributes["items"][key]["category"]
                category_name = data["categories"][category_key]
                category = Category.find_by_default_key(
                    household_id, category_key) or Category.find_by_name(household_id, category_name)
                if not category:
                    category = Category.create_by_name(
                        household_id, category_name, True, category_key)
                if not category.default_key:  # migrate to new system
                    category.default_key = category_key
                    category.save()
                item.category = category
            if not bulkSave:
                item.save(keepDefault=True)
            else:
                models.append(item)

    if bulkSave:
        try:
            db.session.add_all(models)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e
    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")
