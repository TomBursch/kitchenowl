from __future__ import annotations

import gzip
import json
import os
import re
from typing import Any

from app.util.filename_validator import allowed_file


def _normalize_text(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()


def _normalize_instruction_step(value: Any) -> str:
    text = _normalize_text(value)
    if not text:
        return ""
    return re.sub(r"^(?:\d+\s*[\.)]\s+)+", "", text)


def _normalize_int(value: Any) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _parse_minutes(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return int(value)
    text = str(value)
    digits = "".join([c for c in text if c.isdigit() or c == " "])
    parts = [p for p in digits.split(" ") if p]
    if not parts:
        return None
    try:
        return int(parts[0])
    except ValueError:
        return None


def _normalize_items(value: Any) -> list[dict[str, Any]]:
    if not value:
        return []
    if isinstance(value, list):
        items: list[dict[str, Any]] = []
        for entry in value:
            if isinstance(entry, dict):
                name = _normalize_text(
                    entry.get("name") or entry.get("item") or entry.get("ingredient")
                )
                if not name:
                    continue
                quantity = _normalize_text(entry.get("quantity") or entry.get("amount"))
                note = _normalize_text(entry.get("note"))
                description_parts = [p for p in [quantity, note] if p]
                items.append(
                    {
                        "name": name,
                        "description": " ".join(description_parts).strip(),
                        "optional": bool(entry.get("optional", False)),
                    }
                )
            else:
                name = _normalize_text(entry)
                if name:
                    items.append(
                        {
                            "name": name,
                            "description": "",
                            "optional": False,
                        }
                    )
        return items
    return []


def _normalize_step_image(entry: dict[str, Any]) -> str:
    image_sources = [
        entry.get("image"),
        entry.get("photo"),
        entry.get("picture"),
        entry.get("preview_picture"),
        entry.get("step_image"),
        entry.get("stepImage"),
        entry.get("img"),
    ]
    images = entry.get("images")
    if isinstance(images, list):
        image_sources.extend(images)
    for source in image_sources:
        if isinstance(source, dict):
            source = source.get("url") or source.get("src") or source.get("path")
        source_text = _normalize_text(source)
        if source_text:
            return source_text
    return ""


def _is_gzip_bytes(data: bytes) -> bool:
    return len(data) >= 2 and data[0] == 0x1F and data[1] == 0x8B


def _load_json_bytes(data: bytes) -> Any:
    return json.loads(data.decode("utf-8"))


def _maybe_decode_json_payload(data: bytes) -> Any | None:
    if _is_gzip_bytes(data):
        try:
            data = gzip.decompress(data)
        except Exception:
            return None
    try:
        return _load_json_bytes(data)
    except Exception:
        return None


def _normalize_zip_path(path: str) -> str:
    return path.replace("\\", "/").strip("/").lower()


def _collect_zip_images(entries: list[str]) -> dict[str, list[str]]:
    images: dict[str, list[str]] = {}
    for name in entries:
        if allowed_file(name):
            images.setdefault(_normalize_zip_path(os.path.dirname(name)), []).append(
                name
            )
    return images
