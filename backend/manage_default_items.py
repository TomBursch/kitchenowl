import argparse
import json
import os
import requests

from sqlalchemy import desc, func
from app import app
from app.models import Item, Category, Household


BASE_PATH = os.path.dirname(os.path.abspath(__file__))
DEEPL_AUTH_KEY = ""


def update_names(saveToFile: bool = False):
    def nameToKey(name: str) -> str:
        return name.lower().strip().replace(" ", "_")
    for household in Household.query.filter(Household.language != None).all():
        lang_code = household.language
        add_items = [item.obj_to_export_dict() for item in household.items]

        # read en file
        with open(BASE_PATH + "/templates/l10n/en.json", encoding="utf8") as f:
            en = json.load(f)

        # translate original file (used as the key) and write to file
        if lang_code != "en" and not DEEPL_AUTH_KEY:
            continue
        if lang_code != "en":
            deepl_supported_lang: list = [v['language'].lower() for v in json.loads(requests.get("https://api-free.deepl.com/v2/languages?type=source",
                                                                                                 headers={'Authorization': 'DeepL-Auth-Key ' + DEEPL_AUTH_KEY}).content)]
            if lang_code not in deepl_supported_lang:
                print(f"Source language '{lang_code}' not supported by deepl")
                continue

            if os.path.exists(BASE_PATH + "/templates/l10n/" + lang_code + ".json"):
                with open(BASE_PATH + "/templates/l10n/" + lang_code + ".json", "r", encoding="utf8") as f:
                    content = f.read()
                    if content:
                        source = json.loads(content)
                    else:
                        source = {}
            else:
                source = {}

            if "items" not in source:
                source["items"] = {}

            for item in add_items:
                item["original"] = item["name"]
                item["name"] = json.loads(requests.post("https://api-free.deepl.com/v2/translate", {"target_lang": "EN-US", "source_lang": lang_code.upper(), "text": item["name"]},
                                                        headers={'Authorization': 'DeepL-Auth-Key ' + DEEPL_AUTH_KEY}).content)['translations'][0]["text"]

                if (nameToKey(item["name"]) not in source["items"]):
                    source["items"][nameToKey(item["name"])] = item["original"]

            with open(BASE_PATH + "/templates/l10n/" + lang_code + ".json", "w", encoding="utf8") as f:
                f.write(json.dumps(source, ensure_ascii=False,
                        indent=2, sort_keys=True))

        for item in add_items:
            if (nameToKey(item["name"]) not in en["items"]):
                en["items"][nameToKey(item["name"])] = item["name"]

        with open(BASE_PATH + "/templates/l10n/en.json", "w", encoding="utf8") as f:
            f.write(json.dumps(en, ensure_ascii=False, indent=2, sort_keys=True))


def update_attributes(saveToFile: bool = False):
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
        iconItem = Item.query.with_entities(Item.icon, func.count().label('count')).filter(
            Item.default_key == key, Item.icon != None).group_by(Item.icon).order_by(desc("count")).first()
        if iconItem:
            attr["items"][key]['icon'] = iconItem.icon

    # Find item categories
    for key in en["items"].keys():
        filterQuery = Item.query.with_entities(Item.category_id).filter(
            Item.default_key == key, Item.category_id != None).scalar_subquery()
        itemCategory = Category.query.with_entities(Category.default_key, func.count(
        ).label('count')).filter(Category.id.in_(filterQuery), Category.default_key != None).group_by(Category.default_key).order_by(desc("count")).first()
        if itemCategory:
            attr["items"][key]['category'] = itemCategory.default_key

    jsonContent = json.dumps(attr, ensure_ascii=False,
                             indent=2, sort_keys=True)
    if (saveToFile):
        with open(BASE_PATH + "/templates/attributes.json", "w", encoding="utf8") as f:
            f.write(jsonContent)
    else:
        print(jsonContent)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='python manage_default_items.py',
        description='This programms queries the current kitchenowl installation for updated template items (names & icon & category)',
    )
    parser.add_argument('-s', '--save', action='store_true',
                        help="saves the output directly to the templates folder")
    parser.add_argument('-n', '--names', action='store_true',
                        help="collects item names")
    parser.add_argument('-a', '--attributes', action='store_true',
                        help="collects attributes")
    args = parser.parse_args()
    with app.app_context():
        if (args.names and args.save):
            update_names(args.save)
        if (args.attributes):
            update_attributes(args.save)
