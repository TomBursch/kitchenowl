import requests
import json
import os


BASE_PATH = os.path.dirname(os.path.abspath(__file__))

def main():
    # read files
    with open(BASE_PATH + "/l10n/en.json", encoding="utf8") as f:
        en:dict = json.load(f)
    with open(BASE_PATH + "/attributes.json", encoding="utf8") as f:
        attr:dict = json.load(f)

    for key in en["items"].keys():
        if key not in attr["items"]:
            attr["items"][key] = {}
    

    with open(BASE_PATH + "/attributes.json", "w", encoding="utf8") as f:
        f.write(json.dumps(attr, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
