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
    instructions = raw.get("instructions") or raw.get("method")
    if isinstance(instructions, list):
        steps = []
        for entry in instructions:
            if isinstance(entry, dict):
                text = _normalize_instruction_step(
                    entry.get("text") or entry.get("instruction") or entry.get("value")
                )
                if text:
                    steps.append(text)
            else:
                text = _normalize_instruction_step(entry)
                if text:
                    steps.append(text)
        if steps:
            if description:
                description += "\n\n"
            description += "\n".join(
                [f"{idx + 1}. {step}" for idx, step in enumerate(steps)]
            )
    else:
        instructions_text = _normalize_text(instructions)
        if instructions_text:
            if description:
                description += "\n\n"
            description += instructions_text

    recipe: dict[str, Any] = {
        "name": name,
        "description": description,
        "time": _normalize_int(raw.get("time") or raw.get("total_time")),
        "cook_time": _normalize_int(raw.get("cook_time")),
        "prep_time": _normalize_int(raw.get("prep_time")),
        "yields": _normalize_int(
            raw.get("yields") or raw.get("servings") or raw.get("persons_served")
        ),
        "source": _normalize_text(raw.get("source") or raw.get("url")),
        "photo": _normalize_text(
            raw.get("photo") or raw.get("image") or raw.get("preview_picture")
        ),
        "photos": [
            _normalize_text(photo)
            for photo in (raw.get("photos") or raw.get("images") or [])
            if _normalize_text(photo)
        ],
        "items": _normalize_items(raw.get("items") or raw.get("ingredients")),
        "tags": [
            _normalize_text(tag)
            for tag in (raw.get("tags") or [])
            if _normalize_text(tag)
        ],
    }

    if recipe["time"] is None:
        recipe["time"] = _parse_minutes(raw.get("time") or raw.get("total_time"))
    if recipe["cook_time"] is None:
        recipe["cook_time"] = _parse_minutes(raw.get("cook_time"))
    if recipe["prep_time"] is None:
        recipe["prep_time"] = _parse_minutes(raw.get("prep_time"))

    if not recipe["tags"] and isinstance(raw.get("categories"), list):
        recipe["tags"] = [
            _normalize_text(tag)
            for tag in raw.get("categories", [])
            if _normalize_text(tag)
        ]

    if not recipe["photo"]:
        recipe.pop("photo", None)
    if not recipe["photos"]:
        recipe.pop("photos", None)
    return recipe


def json_extract_recipes(payload: Any) -> list[dict[str, Any]]:
    recipes: list[dict[str, Any]] = []
    if isinstance(payload, dict):
        candidates = payload.get("recipes")
        if isinstance(candidates, list):
            for entry in candidates:
                if isinstance(entry, dict):
                    normalized = _normalize_recipe(entry)
                    if normalized:
                        recipes.append(normalized)
        else:
            normalized = _normalize_recipe(payload)
            if normalized:
                recipes.append(normalized)
    elif isinstance(payload, list):
        for entry in payload:
            if isinstance(entry, dict):
                normalized = _normalize_recipe(entry)
                if normalized:
                    recipes.append(normalized)
    return recipes
