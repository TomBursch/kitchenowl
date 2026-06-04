from __future__ import annotations

import io
import os
import re
import uuid
import zipfile
from typing import Any

from app.service.importRecipes.utils import (
    _maybe_decode_json_payload,
    _normalize_text,
    _normalize_instruction_step,
    _parse_minutes,
)
from app import app


def _parse_tandoor_recipe(
    payload: dict[str, Any], inner: zipfile.ZipFile | None, images_dir: str
) -> dict[str, Any] | None:
    name = _normalize_text(payload.get("name"))
    if not name:
        return None

    rec: dict[str, Any] = {}
    rec["name"] = name
    rec["description"] = _normalize_text(payload.get("description"))
    rec["source"] = _normalize_text(payload.get("source_url") or payload.get("source"))

    servings = payload.get("servings")
    if isinstance(servings, (int, float)):
        rec["yields"] = round(servings)
    else:
        rec["yields"] = _normalize_text(payload.get("servings_text")) or None

    def parse_time(val: Any) -> int | None:
        return int(round(val)) if isinstance(val, (int, float)) else _parse_minutes(val)

    rec["prep_time"] = parse_time(payload.get("working_time"))
    rec["cook_time"] = parse_time(payload.get("waiting_time"))

    prep = rec.get("prep_time") or 0
    cook = rec.get("cook_time") or 0
    rec["time"] = (prep + cook) or None

    kws = payload.get("keywords") or []
    tags = []
    for k in kws:
        tag = _normalize_text(k.get("name") if isinstance(k, dict) else k)
        if tag:
            tags.append(tag)
    if tags:
        rec["tags"] = tags

    steps = payload.get("steps") or []
    steps = [s for s in steps if isinstance(s, dict)]
    steps.sort(key=lambda s: s.get("order") or 0)

    instr_lines: list[tuple[str, str]] = []
    items: list[dict[str, Any]] = []

    for s in steps:
        section = _normalize_instruction_step(s.get("name"))
        if section:
            instr_lines.append(("header", section))
        raw_instruction = _normalize_instruction_step(s.get("instruction"))
        if raw_instruction:
            cleaned = re.sub(r"\n{2,}", "\n", raw_instruction.strip())
            instr_lines.append(("step", cleaned))
        ingrs = s.get("ingredients") or []
        for ing in sorted(
            [i for i in ingrs if isinstance(i, dict)], key=lambda x: x.get("order") or 0
        ):
            if ing.get("is_header"):
                continue
            food = ing.get("food") or {}
            food_name = _normalize_text(
                food.get("name") if isinstance(food, dict) else ing.get("name")
            )
            if not food_name:
                continue
            unit = ing.get("unit") or {}
            unit_name = unit.get("name") if isinstance(unit, dict) else None
            amount = ing.get("amount") if not ing.get("no_amount") else None
            note = _normalize_text(ing.get("note") or "")
            parts = [str(p) for p in (amount, unit_name, note) if p not in (None, "")]

            items.append(
                {
                    "name": food_name,
                    "description": " ".join(parts).strip(),
                    "optional": False,
                }
            )

    seen: set[str] = set()
    step_counter = 0
    assembled: list[str] = []
    for kind, text in instr_lines:
        if kind == "header":
            assembled.append(text)
        else:
            if text in seen:
                continue
            seen.add(text)
            step_counter += 1
            assembled.append(f"{step_counter}. {text}")

    if assembled:
        base = rec.get("description", "").strip()
        rec["description"] = (base + "\n\n" if base else "") + "\n".join(assembled)

    if items:
        rec["items"] = items

    if inner is not None:
        image_name = next(
            (n for n in inner.namelist() if os.path.basename(n).lower() == "image.jpg"),
            None,
        )
        if image_name:
            try:
                img_bytes = inner.read(image_name)
                fname = f"{uuid.uuid4()}_{os.path.basename(image_name)}"
                path = os.path.join(images_dir, fname)
                with open(path, "wb") as fh:
                    fh.write(img_bytes)
                rec["photo_temp"] = fname
            except Exception:
                app.logger.warning(
                    "Failed to extract Tandoor image: %s", image_name, exc_info=True
                )

    return rec


def parse_tandoor_zip(
    zf: zipfile.ZipFile,
    entry_names: list[str],
    zip_entries: dict[str, str],
    images_dir: str,
) -> list[dict[str, Any]]:
    recipes: list[dict[str, Any]] = []
    root_zips = [
        n
        for n in entry_names
        if os.path.dirname(n) == "" and n.lower().endswith(".zip")
    ]

    if not root_zips:
        flat_entry = zip_entries.get("recipes.json")
        if flat_entry:
            try:
                payload = _maybe_decode_json_payload(zf.read(flat_entry))
                if isinstance(payload, list):
                    for item in payload:
                        if isinstance(item, dict):
                            rec = _parse_tandoor_recipe(
                                item, inner=None, images_dir=images_dir
                            )
                            if rec:
                                recipes.append(rec)
            except Exception:
                app.logger.warning(
                    "Tandoor flat recipes.json parse failed", exc_info=True
                )
        return recipes

    for zname in root_zips:
        try:
            inner_bytes = zf.read(zname)
            with zipfile.ZipFile(io.BytesIO(inner_bytes)) as inner:
                recipe_json_name = next(
                    (n for n in inner.namelist() if n.lower() == "recipe.json"), None
                )
                if not recipe_json_name:
                    continue
                payload = _maybe_decode_json_payload(inner.read(recipe_json_name))
                if not isinstance(payload, dict):
                    continue
                rec = _parse_tandoor_recipe(payload, inner=inner, images_dir=images_dir)
                if rec:
                    recipes.append(rec)
        except Exception:
            app.logger.warning(
                "Failed to parse Tandoor inner zip: %s", zname, exc_info=True
            )
            continue

    return recipes
