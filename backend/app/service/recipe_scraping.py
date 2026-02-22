import re
from typing import Any
import requests
from app.config import FRONT_URL
from app.errors import ForbiddenRequest
from app.models.recipe import RecipeVisibility
from app.models import Recipe, Household
from app.service.recipe_public_scraping import scrapeHTML, scrapeHTMLLLM


def scrapePublic(url: str, html: str, household: Household) -> dict | None:
    res = scrapeHTML(url, html, household)
    if not res:
        res = scrapeHTMLLLM(url, html, household)
    return res


def scrapeLocal(recipe_id: int, household: Household):
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        return None
    if recipe.visibility == RecipeVisibility.PRIVATE:
        recipe.checkAuthorized()
    recipe.server_scrapes = recipe.server_scrapes + 1
    recipe.save()

    items = {}
    for ingredient in recipe.items:
        items[ingredient.item.name + " " + ingredient.description] = (
            ingredient.obj_to_item_dict()
        )

    return {
        "recipe": recipe.obj_to_dict()
        | {
            "id": None,
            "visibility": RecipeVisibility.PRIVATE,
            "source": "kitchenowl:///recipe/" + str(recipe.id),
        },
        "items": items,
    }


def scrapeKitchenOwl(
    original_url: str, api_url: str, recipe_id: int
) -> dict[str, Any] | None:
    res = requests.get(api_url + "/recipe/" + str(recipe_id))
    if res.status_code != requests.codes.ok:
        if res.status_code == requests.codes.unauthorized:
            raise ForbiddenRequest()
        return None

    recipe = res.json() | {
        "id": None,
        "visibility": RecipeVisibility.PRIVATE,
        "source": original_url,
    }
    if recipe["photo"] is not None:
        recipe["photo"] = api_url + "/upload/" + recipe["photo"]
    items = {}

    for ingredient in recipe["items"]:
        items[ingredient["name"] + " " + ingredient["description"]] = ingredient

    return {"recipe": recipe, "items": items}


def scrape(url: str, household: Household) -> dict[str, Any] | None:
    localMatch = re.match(
        r"(kitchenowl:\/\/|"
        + re.escape((FRONT_URL or "").removesuffix("/"))
        + r")\/recipe\/(\d+)",
        url,
    )
    if localMatch:
        return scrapeLocal(int(localMatch.group(2)), household)

    kitchenowlMatch = re.match(
        r"((https?:\/\/)?app\.kitchenowl\.org|.+)\/recipe\/(\d+)", url
    )
    if kitchenowlMatch and url.startswith("https://app.kitchenowl.org/"):
        return scrapeKitchenOwl(
            url, "https://app.kitchenowl.org/api", int(kitchenowlMatch.group(3))
        )
    if "http" not in url:
        url = "http://" + url

    try:
        res = requests.get(url=url)
    except Exception:
        return None
    if res.status_code != requests.codes.ok:
        return None

    if kitchenowlMatch and "<title>KitchenOwl</title>" in res.text:
        return scrapeKitchenOwl(
            url, kitchenowlMatch.group(1) + "/api", int(kitchenowlMatch.group(3))
        )

    return scrapePublic(url, res.text, household)
