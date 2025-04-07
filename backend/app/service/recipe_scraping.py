import re

import requests
from app.config import FRONT_URL
from app.errors import ForbiddenRequest
from app.models import Recipe, Household
from .recipe_public_scraping import scrapeHTML, scrapeHTMLLLM


def scrapePublic(url: str, html: str, household: Household) -> dict | None:
    res = scrapeHTML(url, html, household)
    if not res:
        res = scrapeHTMLLLM(url, html, household)
    return res


def scrapeLocal(recipe_id: int, household: Household):
    recipe = Recipe.find_by_id(recipe_id)
    recipe.checkAuthorized()
    
    items = {}
    for ingredient in recipe.items:
        items[ingredient.item.name + " " + ingredient.description] = (
            ingredient.obj_to_item_dict()
        )

    return {
        "recipe": recipe.obj_to_dict()
        | {
            "id": None,
            "public": False,
            "source": "kitchenowl:///recipe/" + str(recipe.id),
        },
        "items": items,
    }


def scrapeKitchenOwl(original_url: str, api_url: str, recipe_id: int) -> dict | None:
    res = requests.get(api_url + "/recipe/" + str(recipe_id))
    if res.status_code != requests.codes.ok:
        if res.status_code == requests.codes.unauthorized:
            raise ForbiddenRequest()
        return None

    recipe = res.json()
    recipe["source"] = original_url
    recipe["public"] = False
    if recipe["photo"] is not None:
        recipe["photo"] = api_url + "/upload/" + recipe["photo"]
    items = {}

    for ingredient in recipe["items"]:
        items[ingredient["name"] + " " + ingredient["description"]] = ingredient

    return {"recipe": recipe, "items": items}


def scrape(url: str, household: Household) -> dict | None:
    localMatch = re.fullmatch(
        r"(kitchenowl:\/\/|"
        + re.escape((FRONT_URL or "").removesuffix("/"))
        + r")\/recipe\/(\d+)",
        url,
    )
    if localMatch:
        return scrapeLocal(int(localMatch.group(2)), household)

    kitchenowlMatch = re.fullmatch(
        r"(https?:\/\/app\.kitchenowl\.org|.+)\/recipe\/(\d+)", url
    )
    if kitchenowlMatch and url.startswith("https://app.kitchenowl.org/"):
        return scrapeKitchenOwl(
            url, "https://app.kitchenowl.org/api", int(kitchenowlMatch.group(2))
        )
    if 'http' not in url:
        url = "http://" + url

    try:
        res = requests.get(url=url)
    except:
        return None
    if res.status_code != requests.codes.ok:
        return None

    if (
        kitchenowlMatch
        and "<title>KitchenOwl</title>" in res.text
    ):
        return scrapeKitchenOwl(
            url, kitchenowlMatch.group(1) + "/api", int(kitchenowlMatch.group(2))
        )

    return scrapePublic(url, res.text, household)
