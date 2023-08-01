import requests
import json
import os


SERVER_URL = "http://localhost:5000"
TOKEN = ""
HOUSEHOLD_ID = 1

DEEPL_AUTH_KEY = ""
SOURCE_LANG_CODE = None  # only used if the household has no language assigned

BASE_PATH = os.path.dirname(os.path.abspath(__file__))


def nameToKey(name: str) -> str:
    return name.lower().strip().replace(" ", "_")


def main():
    if not SERVER_URL or not TOKEN:
        print("Server is not configured")
        return
    if not HOUSEHOLD_ID:
        print("Household not configured")
        return

    # Get household from server
    household: dict = json.loads(requests.get(
        SERVER_URL + "/api/household/" + str(HOUSEHOLD_ID), headers={'Authorization': 'Bearer ' + TOKEN}).content)

    if not household:
        print("Could not find household")
        return

    lang_code = household['language'] or SOURCE_LANG_CODE
    if not lang_code:
        print("Household has no language")
        return
    print("Selected household '" +
          household['name'] + "' with language code '" + lang_code + "'")
    confirm = input("Confirm (y):").lower() or "y"
    if not confirm == "y":
        print("Abort")
        return

    if lang_code != "en" and not DEEPL_AUTH_KEY:
        print("For languages other than english an deepl token is required! Make sure the source languages is supported: https://www.deepl.com/docs-api/translate-text/translate-text/")
        return

    # Get item export from server
    add_items: list = json.loads(requests.get(
        SERVER_URL + "/api/household/" + str(HOUSEHOLD_ID) + "/export/items", headers={'Authorization': 'Bearer ' + TOKEN}).content)["items"]
    
    if not add_items:
        print("An error occured")
        return

    # read en file
    with open(BASE_PATH + "/l10n/en.json", encoding="utf8") as f:
        en = json.load(f)

    # translate original file (used as the key) and write to file
    if lang_code != "en":
        deepl_supported_lang: list = [v['language'].lower() for v in json.loads(requests.get("https://api-free.deepl.com/v2/languages?type=source",
                                                    headers={'Authorization': 'DeepL-Auth-Key ' + DEEPL_AUTH_KEY}).content)]
        if lang_code not in deepl_supported_lang:
            print("Source language not supported by deepl")
            return


        if os.path.exists(BASE_PATH + "/l10n/" + lang_code + ".json"):
            with open(BASE_PATH + "/l10n/" + lang_code + ".json", "r", encoding="utf8") as f:
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

        with open(BASE_PATH + "/l10n/" + lang_code + ".json", "w", encoding="utf8") as f:
            f.write(json.dumps(source, ensure_ascii=False,
                    indent=2, sort_keys=True))

    for item in add_items:
        if (nameToKey(item["name"]) not in en["items"]):
            en["items"][nameToKey(item["name"])] = item["name"]

    with open(BASE_PATH + "/l10n/en.json", "w", encoding="utf8") as f:
        f.write(json.dumps(en, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
