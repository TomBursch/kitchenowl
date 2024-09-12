import re
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import SchemaOrgException
from app.config import FRONT_URL
from app.service.ingredient_parsing import parseIngredients

from app.models import Recipe, Item, Household


def scrapePublic(url: str, household: Household) -> dict | None:
    try:
        scraper = scrape_html(None, url, online=True, supported_only=False, wild_mode=True)
    except:
        return None
    recipe = Recipe()
    recipe.name = scraper.title()
    try:
        recipe.time = int(scraper.total_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        recipe.cook_time = int(scraper.cook_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        recipe.prep_time = int(scraper.prep_time())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        yields = re.search(r"\d*", scraper.yields())
        if yields:
            recipe.yields = int(yields.group())
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    description = ""
    try:
        description = scraper.description() + "\n\n"
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
        pass
    try:
        description = description + scraper.instructions()
    except (NotImplementedError, ValueError, TypeError, AttributeError, SchemaOrgException):
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
    recipe.checkAuthorized()

    recipe.source = "kitchenowl:///recipe/" + str(recipe.id)
    items = {}

    for ingredient in recipe.items:
        items[ingredient.item.name + " " + ingredient.description] = ingredient.obj_to_item_dict()

    return {
        "recipe": recipe.obj_to_dict(),
        "items": items,
    }

def scrape(url: str, household: Household) -> dict | None:
    match = re.fullmatch(r"(kitchenowl:\/\/|"+ re.escape((FRONT_URL or "").removesuffix("/")) + r")\/recipe\/(\d+)", url)

    if match:
        return scrapeLocal(int(match.group(2)), household)
    
    return scrapePublic(url, household)
    