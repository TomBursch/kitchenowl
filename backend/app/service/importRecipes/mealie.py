from __future__ import annotations

import os
import re
import zipfile
from collections import defaultdict
from typing import Any

from app.service.importRecipes.utils import (
    _maybe_decode_json_payload,
    _normalize_text,
    _parse_minutes,
)
from app.util.filename_validator import allowed_file


def parse_mealie_zip(
    zf: zipfile.ZipFile, zip_entries: dict[str, str]
) -> list[dict[str, Any]]:
    try:
        database_file = zip_entries.get("database.json")
        if database_file is None:
            return []
        data = zf.read(database_file)
    except Exception:
        return []

    payload = _maybe_decode_json_payload(data) or {}
    if not isinstance(payload, dict):
        return []

    def table(name: str) -> list[dict[str, Any]]:
        v = payload.get(name)
        return v if isinstance(v, list) else []

    def nid(v: Any) -> str | None:
        if v is None:
            return None
        return str(v).lower().replace("-", "").strip()

    # Base tables
    recipes_table = table("recipes")
    instr_table = table("recipe_instructions")
    ingred_table = (
        table("recipes_ingredients")
        or table("recipe_ingredients")
        or table("recipe_ingredient")
    )

    # Lookup dictionaries
    foods_table = {nid(e.get("id")): e for e in table("ingredient_foods")}
    units_table = {nid(e.get("id")): e for e in table("ingredient_units")}
    nutrition_table = {nid(r.get("recipe_id")): r for r in table("recipe_nutrition")}
    tags_table = {nid(t.get("id")): t for t in table("tags")}
    categories_table = {nid(c.get("id")): c for c in table("categories")}

    instr_by_recipe = defaultdict(list)
    for step in instr_table:
        r_id = nid(step.get("recipe_id"))
        if r_id:
            instr_by_recipe[r_id].append(step)

    ingred_by_recipe = defaultdict(list)
    for ing in ingred_table:
        r_id = nid(ing.get("recipe_id"))
        if r_id:
            ingred_by_recipe[r_id].append(ing)

    tags_by_recipe = defaultdict(list)
    for t in table("recipes_to_tags"):
        r_id = nid(t.get("recipe_id"))
        if r_id:
            tags_by_recipe[r_id].append(t.get("tag_id"))

    cats_by_recipe = defaultdict(list)
    for c in table("recipes_to_categories"):
        r_id = nid(c.get("recipe_id"))
        if r_id:
            cats_by_recipe[r_id].append(c.get("category_id"))

    images_by_recipe = {}
    for zip_key, entry in zip_entries.items():
        zip_key_lower = zip_key.lower()
        if (
            "/recipes/" in zip_key_lower
            and os.path.basename(zip_key_lower).startswith("original.")
            and allowed_file(entry)
        ):
            try:
                rid_part = zip_key_lower.split("/recipes/")[1].split("/")[0]
                images_by_recipe[nid(rid_part)] = entry
            except IndexError:
                pass

    recipes: list[dict[str, Any]] = []
    for r in recipes_table:
        rid = r.get("id")
        rid_key = nid(rid)
        name_val = _normalize_text(r.get("name") or r.get("title"))
        if not name_val:
            continue
        description = _normalize_text(r.get("description"))
        if "demo.mealie.io" in description.lower():
            continue

        recipe: dict[str, Any] = {}
        recipe["id"] = rid
        recipe["name"] = name_val
        recipe["description"] = description
        recipe["source"] = _normalize_text(
            r.get("org_url") or r.get("source_url") or r.get("source")
        )
        recipe["slug"] = _normalize_text(r.get("slug"))
        recipe["rating"] = r.get("rating")
        recipe["cuisine"] = _normalize_text(r.get("recipeCuisine") or r.get("cuisine"))

        recipe["prep_time"] = _parse_minutes(
            r.get("prep_time") or r.get("prepTime") or r.get("prepTimeStr")
        )
        recipe["cook_time"] = _parse_minutes(
            r.get("cook_time") or r.get("cookTime") or r.get("cookTimeStr")
        )
        recipe["perform_time"] = _parse_minutes(r.get("perform_time"))
        if recipe["cook_time"] is None:
            recipe["cook_time"] = recipe["perform_time"]
        recipe["time"] = _parse_minutes(
            r.get("total_time") or r.get("totalTime") or r.get("time")
        )
        if recipe["time"] is None:
            prep = recipe.get("prep_time") or 0
            cook = recipe.get("cook_time") or 0
            recipe["time"] = prep + cook if (prep + cook) else None

        servings = r.get("recipe_servings")
        if servings is not None:
            try:
                recipe["yields"] = int(round(float(servings)))
            except Exception:
                recipe["yields"] = None
        else:
            recipe["yields"] = _normalize_text(r.get("recipe_yield"))

        # Grab pre-grouped instructions
        steps = instr_by_recipe.get(rid_key, [])
        steps.sort(key=lambda s: s.get("position") or 0)
        instrs: list[str] = []
        for idx, s in enumerate(steps, start=1):
            title = _normalize_text(s.get("title"))
            text = _normalize_text(
                s.get("text") or s.get("value") or s.get("instruction")
            )
            if title:
                instrs.append(title)
            if text:
                # Strip existing starting numbers/punctuation
                clean_text = re.sub(r"^\d+[\.\)]\s*", "", text)
                instrs.append(f"{idx}. {clean_text}")
        if instrs:
            recipe["description"] = (
                (recipe.get("description") + "\n\n")
                if recipe.get("description")
                else ""
            ) + "\n".join(instrs)

        # Grab pre-grouped ingredients
        ing = ingred_by_recipe.get(rid_key, [])
        ing.sort(key=lambda s: s.get("position") or 0)
        items: list[dict[str, Any]] = []
        for it in ing:
            qty = it.get("quantity")
            note = _normalize_text(it.get("note"))
            orig = _normalize_text(it.get("original_text"))
            food = foods_table.get(nid(it.get("food_id")))
            food_name = _normalize_text(
                food.get("name") if isinstance(food, dict) else None
            )
            unit = units_table.get(nid(it.get("unit_id")))
            unit_name = None
            if isinstance(unit, dict):
                use_abbr = unit.get("use_abbreviation")
                unit_name = unit.get("abbreviation") if use_abbr else unit.get("name")
            parts = []
            if qty not in (None, 0, 0.0):
                parts.append(str(qty))
            if unit_name:
                parts.append(str(unit_name))
            if note:
                parts.append(note)
            desc = " ".join(parts).strip()
            name = (
                food_name
                or orig
                or _normalize_text(it.get("name") or it.get("ingredient"))
            )
            if not name and note:
                name = note
                desc = ""
            if not name:
                continue
            items.append({"name": name, "description": desc, "optional": False})
        if items:
            recipe["items"] = items

        nut = nutrition_table.get(rid_key)
        if isinstance(nut, dict):
            recipe["nutrition"] = {
                k: nut.get(k)
                for k in (
                    "calories",
                    "protein_content",
                    "fat_content",
                    "carbohydrate_content",
                    "fiber_content",
                    "sodium_content",
                    "sugar_content",
                )
                if k in nut
            }

        # Grab pre-grouped tags
        tag_ids = tags_by_recipe.get(rid_key, [])
        tags = [
            tags_table.get(nid(tid) if tid is not None else None, {}).get("name")
            for tid in tag_ids
        ]
        tags = [t for t in tags if t]
        if tags:
            recipe["tags"] = tags

        # Grab pre-grouped categories
        cat_ids = cats_by_recipe.get(rid_key, [])
        cats = [
            categories_table.get(nid(cid) if cid is not None else None, {}).get("name")
            for cid in cat_ids
        ]
        cats = [c for c in cats if c]
        if cats:
            recipe["categories"] = cats

        # Grab pre-mapped image
        mapped_photo = images_by_recipe.get(rid_key)
        if mapped_photo:
            recipe["photo"] = mapped_photo

        recipes.append(recipe)

    return recipes
