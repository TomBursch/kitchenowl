import difflib
import json
from functools import cache

from app.config import APP_DIR


@cache
def known_item_icons() -> tuple[str, ...]:
    """Icon names the app can render (keys of kitchenowl/lib/item_icons.dart).

    templates/item_icons.json is written by icons/generate-item-icons.py.
    """
    with open(f"{APP_DIR}/../templates/item_icons.json", "r", encoding="utf-8") as f:
        return tuple(json.load(f))


@cache
def _known_item_icon_set() -> frozenset[str]:
    return frozenset(known_item_icons())


def is_known_item_icon(icon: str) -> bool:
    return icon in _known_item_icon_set()


def similar_item_icons(icon: str, n: int = 5) -> list[str]:
    return difflib.get_close_matches(icon, known_item_icons(), n=n, cutoff=0.6)
