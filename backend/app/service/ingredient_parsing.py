from collections.abc import Generator
import json
import os
import re
from typing import Any, cast

from flask import current_app
import ingredient_parser
import ingredient_parser.dataclasses
from litellm import completion

from app.config import SUPPORTED_LANGUAGES
from app.models import Household, Item

LLM_MODEL = os.getenv("LLM_MODEL")
LLM_API_URL = os.getenv("LLM_API_URL")
NLP_IF_EN = os.getenv("NLP_IF_EN")

INGREDIENT_SCHEMA = {
    "type": "object",
    "properties": {
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
    "required": ["items"],
    "additionalProperties": False,
}


class IngredientParsingResult:
    originalText: str | None = None
    name: str | None = None
    description: str | None = None
    optional: bool = False

    def __init__(self, original_text, name, description, optional: bool = False):
        self.originalText = original_text
        self.name = name
        self.description = description
        self.optional = optional

    def __str__(self):
        return f"{self.originalText} -> {self.name} ({self.description})"


def parseNLP(ingredients: list[str]) -> list[IngredientParsingResult]:
    def nlpAmountToDescription(
        amount: ingredient_parser.dataclasses.IngredientAmount
        | ingredient_parser.dataclasses.CompositeIngredientAmount,
    ) -> str:
        if isinstance(amount, ingredient_parser.dataclasses.CompositeIngredientAmount):
            return amount.text
        return f"{amount.quantity} {amount.unit}"

    def parseNLPSingle(ingredient: str) -> IngredientParsingResult:
        parsed = ingredient_parser.parse_ingredient(ingredient)
        if isinstance(parsed.name, list):
            name = parsed.name[0].text if parsed.name else None
        else:
            name = parsed.name.text
        description = (
            nlpAmountToDescription(parsed.amount[0]) if len(parsed.amount) > 0 else ""
        )
        # description = description + (" " if description else "") + (parsed.comment.text if parsed.comment else "") # Usually cooking instructions
        return IngredientParsingResult(ingredient, name, description)

    return [parseNLPSingle(e) for e in ingredients]


def parseLLM(
    ingredients: list[str],
    targetLanguageCode: str | None = None,
    household: Household | None = None,
) -> list[IngredientParsingResult] | None:
    if not LLM_MODEL:
        return None

    languageCode = targetLanguageCode or (household.language if household else None)
    language = (
        SUPPORTED_LANGUAGES.get(languageCode, "the same language as the input")
        if languageCode
        else "the same language as the input"
    )
    existing = (
        [e.name for e in Item.all_from_household_by_name(household.id)]
        if household
        else []
    )
    existing_rule = (
        f"\n- If an ingredient matches one of the existing ingredients, use the existing name exactly. Existing ingredients: {json.dumps(existing, ensure_ascii=False)}"
        if existing
        else ""
    )

    systemMessage = f"""
You are an ingredient parser for the recipe app KitchenOwl. Parse every ingredient from the user's list and return only JSON matching this schema:
{json.dumps(INGREDIENT_SCHEMA)}

- items: the ingredients. name is the singular ingredient name without amounts, description is the amount and unit (e.g. "200 g" or "2"), optional is true only for garnishes or optional extras, original_text is the original text of the ingredient as scraped from the website{existing_rule}
- Write all ingredients in {language}

Return only JSON and nothing else.
"""

    messages = [
        {
            "role": "system",
            "content": systemMessage,
        },
        {
            "role": "user",
            "content": json.dumps(ingredients, ensure_ascii=False),
        },
    ]

    response = completion(
        model=cast(str, LLM_MODEL),
        api_base=LLM_API_URL,
        messages=messages,
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "ingredients",
                "strict": True,
                "schema": INGREDIENT_SCHEMA,
            },
        },
        drop_params=True,
    )
    content = response.choices[0].message.content
    # tolerate providers that ignore response_format and wrap the JSON in text or code fences
    data = json.loads(content[content.find("{") : content.rfind("}") + 1])
    llmResponse = data.get("items") or []
    if len(llmResponse) != len(ingredients):
        return None
    parsedIngredients = []
    for i, item in enumerate(llmResponse):
        parsedIngredients.append(
            IngredientParsingResult(
                str(item.get("original_text") or ingredients[i]),
                str(item.get("name") or "").strip()[:128],
                str(item.get("description") or ""),
                bool(item.get("optional")),
            )
        )

    return parsedIngredients


def parseIngredientsStream(
    ingredients: list[str],
    targetLanguageCode: str | None = None,
    sourceLanguageCode: str | None = None,
    household: Household | None = None,
) -> Generator[dict[str, Any], None, list[IngredientParsingResult]]:
    en_pattern = r"^en"

    if LLM_MODEL:
        if not NLP_IF_EN and not re.match(en_pattern, sourceLanguageCode or ""):
            yield {"status": "detecting_ingredients_ai"}
            try:
                res = parseLLM(ingredients, targetLanguageCode, household)
                if res:
                    return res
            except Exception:
                current_app.logger.exception("Error parsing ingredients")
    yield {"status": "detecting_ingredients"}
    return parseNLP(ingredients)


def parseIngredients(
    ingredients: list[str],
    targetLanguageCode: str | None = None,
    sourceLanguageCode: str | None = None,
    household: Household | None = None,
) -> list[IngredientParsingResult]:
    gen = parseIngredientsStream(
        ingredients, targetLanguageCode, sourceLanguageCode, household
    )
    try:
        while True:
            next(gen)
    except StopIteration as e:
        return e.value
