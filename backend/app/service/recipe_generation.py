import json
import os
from typing import Any, cast

from litellm import completion

from app.config import SUPPORTED_LANGUAGES
from app.models import Household, Item
from app.service.ingredient_parsing import LLM_API_URL, LLM_MODEL

LLM_RECIPE_GENERATION = (
    bool(LLM_MODEL) and os.getenv("LLM_RECIPE_GENERATION", "True").lower() == "true"
)

RECIPE_SCHEMA = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "description": {"type": "string"},
        "time": {"type": "integer"},
        "prep_time": {"type": "integer"},
        "cook_time": {"type": "integer"},
        "yields": {"type": "integer"},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "description": {"type": "string"},
                    "optional": {"type": "boolean"},
                },
                "required": ["name", "description", "optional"],
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


def generateRecipe(
    messages: list[dict[str, str]], household: Household
) -> dict[str, Any]:
    language = SUPPORTED_LANGUAGES.get(
        household.language, "the same language as the user's messages"
    )
    # ponytail: sends every item name of the household, filter if households grow into thousands of items
    existing = [e.name for e in Item.all_from_household_by_name(household.id)]
    systemMessage = f"""
You are a recipe creator for the recipe app KitchenOwl. Create the recipe the user describes and return only JSON matching this schema:
{json.dumps(RECIPE_SCHEMA)}

- name: the recipe title
- description: markdown, a short introduction followed by a numbered list of preparation steps
- time, prep_time, cook_time: minutes (time is the total time)
- yields: number of servings
- items: the ingredients. name is the singular ingredient name without amounts, description is the amount and unit (e.g. "200 g" or "2"), optional is true only for garnishes or optional extras
- If an ingredient matches one of the existing ingredients, use the existing name exactly. Existing ingredients: {json.dumps(existing, ensure_ascii=False)}
- When the user asks for changes, return the complete updated recipe
- Write all text in {language}

Return only JSON and nothing else.
"""

    response = completion(
        model=cast(str, LLM_MODEL),
        api_base=LLM_API_URL,
        messages=[{"role": "system", "content": systemMessage}, *messages],
        response_format={
            "type": "json_schema",
            "json_schema": {"name": "recipe", "strict": True, "schema": RECIPE_SCHEMA},
        },
        drop_params=True,
    )
    content = response.choices[0].message.content
    # tolerate providers that ignore response_format and wrap the JSON in text or code fences
    data = json.loads(content[content.find("{") : content.rfind("}") + 1])

    items: dict[str, dict[str, Any]] = {}
    for ingredient in data.get("items") or []:
        name = str(ingredient.get("name") or "").strip()[:128]
        if not name or name.lower() in items:
            continue
        item = Item.find_by_name(household.id, name)
        items[name.lower()] = (item.obj_to_dict() if item else {"name": name}) | {
            "description": str(ingredient.get("description") or ""),
            "optional": bool(ingredient.get("optional")),
        }

    usage = getattr(response, "usage", None)
    return {
        "recipe": {
            "name": str(data.get("name") or "").strip()[:128],
            "description": str(data.get("description") or ""),
            "time": int(data.get("time") or 0),
            "prep_time": int(data.get("prep_time") or 0),
            "cook_time": int(data.get("cook_time") or 0),
            "yields": int(data.get("yields") or 0),
            "items": list(items.values()),
        },
        "usage": {
            "prompt_tokens": getattr(usage, "prompt_tokens", 0) or 0,
            "completion_tokens": getattr(usage, "completion_tokens", 0) or 0,
            "total_tokens": getattr(usage, "total_tokens", 0) or 0,
        },
    }
