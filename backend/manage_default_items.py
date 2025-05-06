import argparse
import json
import os
import requests

from sqlalchemy import desc, func
from app import app
from app.config import STORAGE_PATH
from app.models import Item, Category, Household


BASE_PATH = os.path.dirname(os.path.abspath(__file__))
EXPORT_FOLDER = STORAGE_PATH + "/export"
DEEPL_AUTH_KEY = os.getenv("DEEPL_AUTH_KEY", "")


def update_names(saveToTemplate: bool = False, consensus_count: int = 2):
    default_items: dict[str, dict] = {}

    def nameToKey(name: str) -> str:
        return name.lower().strip().replace(" ", "_")

    def loadLang(lang: str):
        default_items[lang] = {"items": {}}
        if os.path.exists(BASE_PATH + "/templates/l10n/" + lang + ".json"):
            with open(
                BASE_PATH + "/templates/l10n/" + lang + ".json", "r", encoding="utf8"
            ) as f:
                default_items[lang] = json.loads(f.read())

    supported_lang: list = (
        [
            v["language"].lower()
            for v in json.loads(
                requests.get(
                    "https://api-free.deepl.com/v2/languages?type=source",
                    headers={"Authorization": "DeepL-Auth-Key " + DEEPL_AUTH_KEY},
                ).content
            )
        ]
        if DEEPL_AUTH_KEY
        else ["en"]
    )
    loadLang("en")

    items = (
        Item.query.with_entities(
            Item.name, func.count().label("count"), Household.language
        )
        .filter(Item.default_key == None, Household.language.in_(supported_lang))
        .join(Household, isouter=True)
        .group_by(Item.name, Household.language)
        .having(func.count().label("count") >= consensus_count)
        .order_by(desc("count"))
        .all()
    )
    for item in items:
        if item.language == "en":
            if nameToKey(item.name) not in default_items["en"]["items"]:
                default_items["en"]["items"][nameToKey(item.name)] = item.name
        else:
            if item.language not in default_items:
                loadLang(item.language)
            engl_name = json.loads(
                requests.post(
                    "https://api-free.deepl.com/v2/translate",
                    {
                        "target_lang": "EN-US",
                        "source_lang": item.language.upper(),
                        "text": item.name,
                    },
                    headers={"Authorization": "DeepL-Auth-Key " + DEEPL_AUTH_KEY},
                ).content
            )["translations"][0]["text"]
            if nameToKey(engl_name) not in default_items[item.language]["items"]:
                default_items[item.language]["items"][nameToKey(engl_name)] = item.name
            if nameToKey(engl_name) not in default_items["en"]["items"]:
                default_items["en"]["items"][nameToKey(engl_name)] = engl_name

    folder = BASE_PATH + "/templates/l10n/" if saveToTemplate else (EXPORT_FOLDER + "/")
    for key, content in default_items.items():
        with open(folder + key + ".json", "w", encoding="utf8") as f:
            f.write(json.dumps(content, ensure_ascii=False, indent=2, sort_keys=True))


def update_attributes(saveToTemplate: bool = False):
    # read files
    with open(BASE_PATH + "/templates/l10n/en.json", encoding="utf8") as f:
        en: dict = json.load(f)
    with open(BASE_PATH + "/templates/attributes.json", encoding="utf8") as f:
        attr: dict = json.load(f)

    unkownKeys = []
    # Remove unkown keys from attributes file
    for key in attr["items"].keys():
        if key not in en["items"]:
            unkownKeys.append(key)
    for key in unkownKeys:
        attr["items"].pop(key)

    # Find item icons
    for key in en["items"].keys():
        # Add key to map
        if key not in attr["items"]:
            attr["items"][key] = {}
        # Find icon consesus
        iconItem = (
            Item.query.with_entities(Item.icon, func.count().label("count"))
            .filter(Item.default_key == key, Item.icon != None)
            .group_by(Item.icon)
            .order_by(desc("count"))
            .first()
        )
        if iconItem:
            attr["items"][key]["icon"] = iconItem.icon

    # Find item categories
    for key in en["items"].keys():
        filterQuery = (
            Item.query.with_entities(Item.category_id)
            .filter(Item.default_key == key, Item.category_id != None)
            .scalar_subquery()
        )
        itemCategory = (
            Category.query.with_entities(
                Category.default_key, func.count().label("count")
            )
            .filter(Category.id.in_(filterQuery), Category.default_key != None)
            .group_by(Category.default_key)
            .order_by(desc("count"))
            .first()
        )
        if itemCategory:
            attr["items"][key]["category"] = itemCategory.default_key

    jsonContent = json.dumps(attr, ensure_ascii=False, indent=2, sort_keys=True)
    if saveToTemplate:
        with open(BASE_PATH + "/templates/attributes.json", "w", encoding="utf8") as f:
            f.write(jsonContent)
    else:
        with open(EXPORT_FOLDER + "/attributes.json", "w", encoding="utf8") as f:
            f.write(jsonContent)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="python manage_default_items.py",
        description="This programms queries the current kitchenowl installation for updated template items (names & icon & category)",
    )
    parser.add_argument(
        "-s",
        "--save",
        action="store_true",
        help="saves the output directly to the templates folder",
    )
    parser.add_argument(
        "-n", "--names", action="store_true", help="collects item names"
    )
    parser.add_argument(
        "-a", "--attributes", action="store_true", help="collects attributes"
    )
    parser.add_argument(
        "-c--consensus",
        type=int,
        default=2,
        help="Minimum number of households to have this item for it to be considered default",
    )
    args = parser.parse_args()
    if not args.names and not args.attributes:
        parser.print_help()
    else:
        if args.save and not os.path.exists(EXPORT_FOLDER):
            os.makedirs(EXPORT_FOLDER)
        with app.app_context():
            if args.names:
                update_names(args.save, args.c__consensus)
            if args.attributes:
                update_attributes(args.save)
