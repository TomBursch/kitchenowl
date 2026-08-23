from __future__ import annotations

import json
import os
import threading
import urllib.request
from typing import Optional

from app import db
from app.models import Category

# Optional external grocery classifier (e.g. julianpoy/grocery-categorizer).
# When set, newly created items without a category are classified automatically.
# Point this at the classifier's base URL, e.g. http://categorizer:8000
CLASSIFIER_URL = os.getenv("ITEM_CLASSIFIER_URL", "").rstrip("/")

# Seconds to wait for the classifier before giving up (item stays uncategorized).
CLASSIFIER_TIMEOUT = float(os.getenv("ITEM_CLASSIFIER_TIMEOUT", "2"))

# Optional JSON override mapping classifier aisles to category names, e.g.
# {"meat": "🥩 Meat", "seafood": "🐟 Seafood"} — categories are looked up by
# (household-localized) name; unknown names fall back to the default map.
CLASSIFIER_CATEGORY_MAP: dict[str, str] = json.loads(
    os.getenv("ITEM_CLASSIFIER_CATEGORY_MAP", "{}")
)

# Default map: classifier aisle -> KitchenOwl default category key.
# Uses only the ten default categories so this works on any household.
AISLE_TO_DEFAULT_CATEGORY_KEY = {
    "produce": "fruits_vegetables",
    "dairy": "dairy",
    "meat": "refrigerated",
    "seafood": "refrigerated",
    "bakery": "bread",
    "baking": "grain",
    "spices": "canned",
    "grocery": "canned",
    "condiments": "canned",
    "beverages": "drinks",
    "liquor": "drinks",
    "nonfood": "hygiene",
    "frozen": "freezer",
    "canned": "canned",
}

_classification_cache: dict[tuple[int, str], Optional[str]] = {}
_cache_lock = threading.Lock()


def classifier_enabled() -> bool:
    return bool(CLASSIFIER_URL)


def _classify(name: str) -> Optional[str]:
    """Ask the external classifier for an aisle. Returns None on any failure."""
    if not CLASSIFIER_URL:
        return None
    try:
        body = json.dumps({"items": [name]}).encode()
        req = urllib.request.Request(
            CLASSIFIER_URL + "/categorize",
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=CLASSIFIER_TIMEOUT) as resp:
            data = json.loads(resp.read().decode())
        result = data["results"][0]
        if result.get("uncertain") and not os.getenv(
            "ITEM_CLASSIFIER_ALLOW_UNCERTAIN", ""
        ).lower() in ("1", "true", "yes"):
            return None
        return str(result["category"])
    except Exception:
        return None


def suggest_category(household_id: int, name: str) -> Optional[Category]:
    """Classify an item name and return a matching household category.

    Never raises: on any failure the item simply stays uncategorized,
    matching the behavior of an unpatched instance.
    """
    if not classifier_enabled() or not name or not name.strip():
        return None

    key = (household_id, name.strip().lower())
    with _cache_lock:
        if key in _classification_cache:
            aisle = _classification_cache[key]
        else:
            aisle = _classify(name.strip())
            _classification_cache[key] = aisle
    if not aisle:
        return None

    return _category_for_aisle(household_id, aisle)


def _category_for_aisle(household_id: int, aisle: str) -> Optional[Category]:
    override = CLASSIFIER_CATEGORY_MAP.get(aisle)
    if override:
        category = Category.find_by_name(household_id, override)
        if category:
            return category
    default_key = AISLE_TO_DEFAULT_CATEGORY_KEY.get(aisle)
    if not default_key:
        return None
    try:
        return Category.find_by_default_key(household_id, default_key)
    except Exception:
        db.session.rollback()
        return None
