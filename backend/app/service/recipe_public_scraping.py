import json
import re
import os
from typing import Any, cast
from urllib.parse import urljoin, urlparse
from flask import current_app
from html_text import extract_text
from litellm import completion
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import SchemaOrgException
from app.models.tag import Tag
from app.service.ingredient_parsing import parseIngredients
from app.models import Recipe, Item, Household
from app.config import SUPPORTED_LANGUAGES

LLM_MODEL = os.getenv("LLM_MODEL")
LLM_API_URL = os.getenv("LLM_API_URL")

RECIPE_SCHEMA = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "description": {"type": "string"},
        "time": {"type": "integer"},
        "prep_time": {"type": "integer"},
        "cook_time": {"type": "integer"},
        "yields": {"type": "integer"},
        "tags": {"type": "array", "items": {"type": "string"}},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "description": {"type": "string"},
                    "optional": {"type": "boolean"},
                    "original_text": {"type": "string"},
                },
                "required": ["name", "description", "optional", "original_text"],
                "additionalProperties": False,
            },
        },
    },
    "required": [
        "name",
        "description",
        "time",
        "prep_time",
        "cook_time",
        "yields",
        "items",
    ],
    "additionalProperties": False,
}


def fixRelativeUrl(url: str, baseUrl: str) -> str:
    """
    If the URL is already absolute (i.e. includes a scheme and host), returns the unchanged URL.
    Otherwise, i.e. if the URL is relative, returns an absolute URL of the resource relative to baseUrl.
    """
    parsedUrl = urlparse(url)
    if parsedUrl.hostname:
        return url

    return urljoin(baseUrl, url)


def scrapeHTML(url: str, html: str, household: Household) -> dict[str, Any] | None:
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
    recipe.photo = fixRelativeUrl(scraper.image(), url)
    recipe.source = url
    items = {}
    # Relies on site meta data to detect language. Possible mismatch if there is a spanish recipe on a english website
    sourceLanguageCode = (
        scraper.language() or ""
    )  # Fallback to handle None cases and default to LLM if in use
    for ingredient in parseIngredients(
        scraper.ingredients(), household.language, sourceLanguageCode
    ):
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

    language = SUPPORTED_LANGUAGES.get(
        household.language, "the same language as the user's messages"
    )

    existing = [e.name for e in Item.all_from_household_by_name(household.id)]
    systemMessage = f"""
You are a recipe creator for the recipe app KitchenOwl. Create the recipe the scraped website describes and return only JSON matching this schema:
{json.dumps(RECIPE_SCHEMA)}

- name: the recipe title
- description: markdown, a short introduction followed by a numbered list of preparation steps. It supports following additional markdown: ingredient pills allow you to reference ingredients from inside your recipes' description and automatically add amounts to it. It's case-insensitive and uses underscores for spaces. `@ingredient_name` You can also override the item description for that text occurrence by using curly braces: `@ingredient_name{{300g}}`
- time, prep_time, cook_time: minutes (time is the total time)
- yields: number of servings
- tags: optional, a list of tags for the recipe from the following list: {", ".join(tag.name for tag in household.tags)}
- items: the ingredients. name is the singular ingredient name without amounts, description is the amount and unit (e.g. "200 g" or "2"), optional is true only for garnishes or optional extras, original_text is the original text of the ingredient as scraped from the website
- If an ingredient matches one of the existing ingredients, use the existing name exactly. Existing ingredients: {json.dumps(existing, ensure_ascii=False)}
- Write all ingredients in {language} keep the original description and steps in the source language

Return only JSON and nothing else.
"""

    text = extract_text(html)
    if not text.strip():
        return None

    messages = [
        {
            "role": "system",
            "content": systemMessage,
        },
        {
            "role": "user",
            "content": text,
        },
    ]

    try:
        response = completion(
            model=cast(str, LLM_MODEL),
            api_base=LLM_API_URL,
            messages=messages,
            response_format={
                "type": "json_schema",
                "json_schema": {
                    "name": "recipe",
                    "strict": True,
                    "schema": RECIPE_SCHEMA,
                },
            },
            drop_params=True,
        )

        content = response.choices[0].message.content
        # tolerate providers that ignore response_format and wrap the JSON in text or code fences
        data = json.loads(content[content.find("{") : content.rfind("}") + 1])
    except Exception:
        current_app.logger.exception("LLM recipe scraping failed")
        return None

    tags = []
    for tag in data.get("tags") or []:
        t = Tag.find_by_name(household.id, tag)
        if t:
            tags.append(t.obj_to_dict())

    items: dict[str, dict[str, Any]] = {}
    for ingredient in data.get("items") or []:
        name = str(ingredient.get("name") or "").strip()[:128]
        if not name or (ingredient.get("original_text") or name) in items:
            continue
        item = Item.find_by_name(household.id, name)
        items[ingredient.get("original_text") or name] = (
            item.obj_to_dict() if item else {"name": name}
        ) | {
            "description": str(ingredient.get("description") or ""),
            "optional": bool(ingredient.get("optional")),
        }

    return {
        "recipe": {
            "name": str(data.get("name") or "").strip()[:128],
            "description": str(data.get("description") or ""),
            "time": int(data.get("time") or 0),
            "prep_time": int(data.get("prep_time") or 0),
            "cook_time": int(data.get("cook_time") or 0),
            "yields": int(data.get("yields") or 0),
            "tags": tags,
            "items": list(items.values()),
        }
        | {
            "id": None,
            "public": False,
            "source": url,
        },
        "items": items,
    }
