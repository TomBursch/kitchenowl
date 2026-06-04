from __future__ import annotations

from typing import Any
from app.service.importRecipes.utils import (
    _normalize_text,
    _normalize_instruction_step,
    _normalize_int,
    _parse_minutes,
    _normalize_items,
)


def _normalize_recipe(raw: dict[str, Any]) -> dict[str, Any] | None:
    name = _normalize_text(raw.get("name") or raw.get("title") or raw.get("headline"))
    if not name:
        return None

    description = _normalize_text(raw.get("description") or "")
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
            text = _normalize_instruction_step(raw_text)
            if text:
                steps.append(text)

        if steps:
            description = (description + "\n\n" if description else "") + "\n".join(
                f"{idx + 1}. {step}" for idx, step in enumerate(steps)
            )
    else:
        instructions_text = _normalize_text(instructions)
        if instructions_text:
            description = (
                description + "\n\n" if description else ""
            ) + instructions_text

    def parse_time(*keys: str) -> int | None:
        for k in keys:
            val = raw.get(k)
            if val:
                res = _normalize_int(val) or _parse_minutes(val)
                if res is not None:
                    return res
        return None

    recipe: dict[str, Any] = {
        "name": name,
        "description": description,
        "time": parse_time("time", "total_time", "totalTime"),
        "cook_time": parse_time("cook_time", "cookTime"),
        "prep_time": parse_time("prep_time", "prepTime"),
        "yields": _normalize_int(
            raw.get("yields")
            or raw.get("servings")
            or raw.get("persons_served")
            or raw.get("recipeYield")
        ),
        "source": _normalize_text(raw.get("source") or raw.get("url")),
        "cuisine": _normalize_text(raw.get("cuisine") or raw.get("recipeCuisine")),
        "items": _normalize_items(
            raw.get("items") or raw.get("ingredients") or raw.get("recipeIngredient")
        ),
    }

    photo = _normalize_text(
        raw.get("photo") or raw.get("image") or raw.get("preview_picture")
    )
    if photo:
        recipe["photo"] = photo
    photos = [
        _normalize_text(photo)
        for photo in (raw.get("photos") or raw.get("images") or [])
        if _normalize_text(photo)
    ]
    if photos:
        recipe["photos"] = photos

    raw_tags = (
        raw.get("tags") or raw.get("categories") or raw.get("recipeCategory") or []
    )
    if isinstance(raw_tags, str):
        raw_tags = [t.strip() for t in raw_tags.split(",")]

    tags = [_normalize_text(tag) for tag in raw_tags if _normalize_text(tag)]
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
