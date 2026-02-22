import json
import re
import os

from litellm import completion
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import SchemaOrgException
from app.service.ingredient_parsing import parseIngredients
from app.models import Recipe, Item, Household
from app.config import SUPPORTED_LANGUAGES

LLM_MODEL = os.getenv("LLM_MODEL")
LLM_API_URL = os.getenv("LLM_API_URL")


def scrapeHTML(url: str, html: str, household: Household) -> dict | None:
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


def scrapeHTMLLLM(url: str, html: str, household: Household) -> dict | None:
    if not LLM_MODEL:
        return None

    systemMessage = """
You are a tool that returns only JSON and nothing else. You get a html page of a recipe as an input. You return the json in the form {"name": "recipe name", "photo": "url to photo", "description": "description with instructions in markdown", "yields": "servings count", "time": integer total cooking time in minutes, "ingredients" ["list of string ingrediends including amount name and description"]}.

For example a result in English:
{
  "name": "Pumpkin Soup",
  "photo": "https://recipes.com/photos/1283010293.jpg",
  "description": "Delicious soup.
- First wash the pumpkin
- Cut Pumpkin
- Make soup",
  "yields": 4,
  "time": 20,
  "ingredients": [
    "1 Pumpkin",
    "50g red Onions"
  ]
}

Return only JSON and nothing else.
"""

    messages = [
        {
            "role": "system",
            "content": systemMessage,
        }
    ]
    if household.language in SUPPORTED_LANGUAGES:
        messages.append(
            {
                "role": "user",
                "content": f"Translate the response to {SUPPORTED_LANGUAGES[household.language]}. Translate the JSON content to {SUPPORTED_LANGUAGES[household.language]}. Your target language is {SUPPORTED_LANGUAGES[household.language]}. Respond in {SUPPORTED_LANGUAGES[household.language]} from the start.",
            }
        )

    messages.append(
        {
            "role": "user",
            "content": html,
        }
    )

    response = completion(
        model=LLM_MODEL,
        api_base=LLM_API_URL,
        # response_format={"type": "json_object"},
        messages=messages,
    )

    print(response.choices[0].message.content)
    try:
        llmResponse = json.loads(response.choices[0].message.content)
    except Exception as e:
        print(e)
        return None

    items = {}
    for ingredient in parseIngredients(llmResponse["ingredients"], household.language):
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
        "recipe": llmResponse
        | {
            "id": None,
            "public": False,
            "source": url,
        },
        "items": items,
    }
