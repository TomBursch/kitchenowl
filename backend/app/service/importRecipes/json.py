from __future__ import annotations

from typing import Any
from app.service.importRecipes.utils import (
    normalize_text,
    normalize_instruction_step,
    normalize_int,
    normalize_items,
    parse_time,
)


def _normalize_recipe(raw: dict[str, Any]) -> dict[str, Any] | None:
    name = normalize_text(raw.get("name") or raw.get("title") or raw.get("headline"))
    if not name:
        return None

    description = normalize_text(raw.get("description") or "")
    instructions = (
        raw.get("recipeInstructions") or raw.get("instructions") or raw.get("method")
    )
    if isinstance(instructions, list):
        steps = []
        for entry in instructions:
            raw_text = (
                entry.get("text") or entry.get("instruction") or entry.get("value")
                if isinstance(entry, dict)
                else entry
            )
            text = normalize_instruction_step(raw_text)
            if text:
                steps.append(text)

        if steps:
            description = (description + "\n\n" if description else "") + "\n".join(
                f"{idx + 1}. {step}" for idx, step in enumerate(steps)
            )
    else:
        instructions_text = normalize_text(instructions)
        if instructions_text:
            description = (
                description + "\n\n" if description else ""
            ) + instructions_text

    recipe: dict[str, Any] = {
        "name": name,
        "description": description,
        "cook_time": parse_time(raw, "cook_time", "cookTime"),
        "prep_time": parse_time(raw, "prep_time", "prepTime"),
        "time": parse_time(raw, "time", "total_time", "totalTime"),
        "yields": normalize_int(
            raw.get("yields")
            or raw.get("servings")
            or raw.get("persons_served")
            or raw.get("recipeYield")
        ),
        "source": normalize_text(raw.get("source") or raw.get("url")),
        "cuisine": normalize_text(raw.get("cuisine") or raw.get("recipeCuisine")),
        "items": normalize_items(
            raw.get("items") or raw.get("ingredients") or raw.get("recipeIngredient")
        ),
    }

    if recipe["time"] is None:
        prep = recipe.get("prep_time") or 0
        cook = recipe.get("cook_time") or 0
        if (prep + cook) > 0:
            recipe["time"] = prep + cook

    photo = normalize_text(
        raw.get("photo") or raw.get("image") or raw.get("preview_picture")
    )
    if photo:
        recipe["photo"] = photo
    photos = [
        normalize_text(photo)
        for photo in (raw.get("photos") or raw.get("images") or [])
        if normalize_text(photo)
    ]
    if photos:
        recipe["photos"] = photos

    raw_tags = (
        raw.get("tags") or raw.get("categories") or raw.get("recipeCategory") or []
    )
    if isinstance(raw_tags, str):
        raw_tags = [t.strip() for t in raw_tags.split(",")]

    tags = [normalize_text(tag) for tag in raw_tags if normalize_text(tag)]
    if tags:
        recipe["tags"] = tags

    nutrition = raw.get("nutrition")
    if isinstance(nutrition, dict):
        recipe["nutrition"] = nutrition

    return recipe


def json_extract_recipes(payload: Any) -> list[dict[str, Any]]:
    recipes: list[dict[str, Any]] = []

    def add_if_valid(entry: Any):
        if isinstance(entry, dict):
            normalized = _normalize_recipe(entry)
            if normalized:
                recipes.append(normalized)

    if isinstance(payload, dict):
        candidates = (
            payload.get("recipes") or payload.get("data") or payload.get("@graph")
        )
        if isinstance(candidates, list):
            for entry in candidates:
                add_if_valid(entry)
        else:
            add_if_valid(payload)

    elif isinstance(payload, list):
        for entry in payload:
            add_if_valid(entry)

    return recipes
