from typing import cast
import ingredient_parser
import ingredient_parser.dataclasses
from litellm import completion
import json
import os

from app.config import SUPPORTED_LANGUAGES

LLM_MODEL = os.getenv("LLM_MODEL")
LLM_API_URL = os.getenv("LLM_API_URL")


class IngredientParsingResult:
    originalText: str | None = None
    name: str | None = None
    description: str | None = None

    def __init__(self, original_text, name, description):
        self.originalText = original_text
        self.name = name
        self.description = description

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
        name = parsed.name[0].text if len(parsed.name) > 0 else None
        description = (
            nlpAmountToDescription(parsed.amount[0]) if len(parsed.amount) > 0 else ""
        )
        # description = description + (" " if description else "") + (parsed.comment.text if parsed.comment else "") # Usually cooking instructions
        return IngredientParsingResult(ingredient, name, description)

    return [parseNLPSingle(e) for e in ingredients]


def parseLLM(
    ingredients: list[str], targetLanguageCode: str | None = None
) -> list[IngredientParsingResult] | None:
    systemMessage = """
You are a tool that returns only JSON in the form of [{"name": name, "description": description}, ...]. Split every string from the list into these two properties. You receive recipe ingredients and fill the name field with the singular name of the ingredient and everything else is the description. Translate the response into the specified language.

For example in English:
Given: ["300g of Rice", "2 Chocolates"] you return only:
[{"name": "Rice", "description": "300g"}, {"name": "Chocolate", "description": "2"}]

Return only JSON and nothing else.
""" + (
        f"Translate the response to {SUPPORTED_LANGUAGES[targetLanguageCode]}. Translate the JSON content to {SUPPORTED_LANGUAGES[targetLanguageCode]}. Your target language is {SUPPORTED_LANGUAGES[targetLanguageCode]}. Respond in {SUPPORTED_LANGUAGES[targetLanguageCode]} from the start."
        if targetLanguageCode in SUPPORTED_LANGUAGES
        else ""
    )

    messages = [
        {
            "role": "system",
            "content": systemMessage,
        }
    ]
    if targetLanguageCode in SUPPORTED_LANGUAGES:
        messages.append(
            {
                "role": "user",
                "content": f"Translate the response to {SUPPORTED_LANGUAGES[targetLanguageCode]}. Translate the JSON content to {SUPPORTED_LANGUAGES[targetLanguageCode]}. Your target language is {SUPPORTED_LANGUAGES[targetLanguageCode]}. Respond in {SUPPORTED_LANGUAGES[targetLanguageCode]} from the start.",
            }
        )

    messages.append(
        {
            "role": "user",
            "content": json.dumps(ingredients),
        }
    )

    response = completion(
        model=cast(str, LLM_MODEL),
        api_base=LLM_API_URL,
        # response_format={"type": "json_object"},
        messages=messages,
    )
    llmResponse = json.loads(response.choices[0].message.content)
    if len(llmResponse) != len(ingredients):
        return None
    parsedIngredients = []
    for i in range(len(llmResponse)):
        parsedIngredients.append(
            IngredientParsingResult(
                ingredients[i], llmResponse[i]["name"], llmResponse[i]["description"]
            )
        )

    return parsedIngredients


def parseIngredients(
    ingredients: list[str],
    targetLanguageCode=None,
) -> list[IngredientParsingResult]:
    if LLM_MODEL:
        try:
            return parseLLM(ingredients, targetLanguageCode) or parseNLP(ingredients)
        except Exception as e:
            print("Error parsing ingredients:", e)

    return parseNLP(ingredients)
