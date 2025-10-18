import re
from typing import Any
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import SchemaOrgException
import requests
from app.config import FRONT_URL
from app.errors import ForbiddenRequest
from app.models.recipe import RecipeVisibility
from app.service.ingredient_parsing import parseIngredients

from app.models import Recipe, Item, Household


def scrapePublic(url: str, html: str, household: Household) -> dict[str, Any] | None:
    try:
        scraper = scrape_html(html, url, supported_only=False)
    except Exception:
        return None
    recipe = Recipe()
    try:
        recipe.name = scraper.title().strip()[:128]
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        return None  # Unsupported if title cannot be scraped
    try:
        recipe.time = int(scraper.total_time())
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    try:
        recipe.cook_time = int(scraper.cook_time())
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    try:
        recipe.prep_time = int(scraper.prep_time())
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    try:
        yields = re.search(r"\d*", scraper.yields())
        if yields:
            recipe.yields = int(yields.group())
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    description = ""
    try:
        description = scraper.description() + "\n\n"
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    try:
        description = description + scraper.instructions()
    except (
        NotImplementedError,
        ValueError,
        TypeError,
        AttributeError,
        SchemaOrgException,
    ):
        pass
    recipe.description = description
    recipe.photo = scraper.image()
    recipe.source = url
    items = {}
    for ingredient in parseIngredients(scraper.ingredients(), household.language):
        name = ingredient.name if ingredient.name else ingredient.originalText or ""
        item = Item.find_name_starts_with(household.id, name)
        if item:
            items[ingredient.originalText] = item.obj_to_dict() | {
                "description": ingredient.description,
                "optional": False,
            }
        else:
            items[ingredient.originalText] = None
    return {
        "recipe": recipe.obj_to_dict(),
        "items": items,
    }


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
