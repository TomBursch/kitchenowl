import requests
import json
import os


SERVER_URL = "http://localhost:5000"
TOKEN = ""

DEEPL_AUTH_KEY = ""
SOURCE_LANG_CODE = ""

BASE_PATH = os.path.dirname(os.path.abspath(__file__))


def nameToKey(name: str) -> str:
    return name.lower().strip().replace(" ", "_")


def main():
    if not SOURCE_LANG_CODE:
        print("Missing source language")
        return
    if SOURCE_LANG_CODE != "en" and not DEEPL_AUTH_KEY:
        print("For languages other than english an deepl token is required! Make sure the source languages is supported: https://www.deepl.com/docs-api/translate-text/translate-text/")
        return
    if SOURCE_LANG_CODE != "en" and not DEEPL_AUTH_KEY:
        print("For languages other than english an deepl token is required! Make sure the source languages is supported: https://www.deepl.com/docs-api/translate-text/translate-text/")
        return
    if not SERVER_URL or not TOKEN:
        print("Server is not configured")
        return

    # Get item export from server
    add_items: list = json.loads(requests.get(
        SERVER_URL + "/api/export/items", headers={'Authorization': 'Bearer ' + TOKEN}).content)["items"]

    # read en file
    with open(BASE_PATH + "/l10n/en.json", encoding="utf8") as f:
        en = json.load(f)

    # translate original file (used as the key) and write to file
    if SOURCE_LANG_CODE != "en":
        if os.path.exists(BASE_PATH + "/l10n/" + SOURCE_LANG_CODE + ".json"):
            with open(BASE_PATH + "/l10n/" + SOURCE_LANG_CODE + ".json", "r", encoding="utf8") as f:
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
            item["name"] = json.loads(requests.post("https://api-free.deepl.com/v2/translate", {"target_lang": "EN-US", "source_lang": SOURCE_LANG_CODE.upper(), "text": item["name"]},
                                                    headers={'Authorization': 'DeepL-Auth-Key ' + DEEPL_AUTH_KEY}).content)['translations'][0]["text"]

            if (nameToKey(item["name"]) not in source["items"]):
                source["items"][nameToKey(item["name"])] = item["original"]

        with open(BASE_PATH + "/l10n/" + SOURCE_LANG_CODE + ".json", "w", encoding="utf8") as f:
            f.write(json.dumps(source, ensure_ascii=False,
                    indent=2, sort_keys=True))

    for item in add_items:
        if (nameToKey(item["name"]) not in en["items"]):
            en["items"][nameToKey(item["name"])] = item["name"]

    with open(BASE_PATH + "/l10n/en.json", "w", encoding="utf8") as f:
        f.write(json.dumps(en, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
