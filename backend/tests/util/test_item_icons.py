import json
import os
import re

import pytest

from app.config import PROJECT_DIR
from app.util.item_icons import is_known_item_icon, known_item_icons, similar_item_icons

FRONTEND_ICONS = os.path.join(PROJECT_DIR, "..", "kitchenowl", "lib", "item_icons.dart")


def test_known_item_icons_are_sorted_and_unique():
    icons = known_item_icons()
    assert list(icons) == sorted(set(icons))
    assert is_known_item_icon("mushroom")
    assert not is_known_item_icon("mushrooms")
    assert "mushroom" in similar_item_icons("mushrooms")


def test_default_items_use_known_icons():
    with open(
        os.path.join(PROJECT_DIR, "templates", "attributes.json"), encoding="utf-8"
    ) as f:
        attributes = json.load(f)
    used = {v["icon"] for v in attributes["items"].values() if "icon" in v}
    assert used - set(known_item_icons()) == set()


@pytest.mark.skipif(
    not os.path.exists(FRONTEND_ICONS), reason="frontend sources not available"
)
def test_known_item_icons_match_frontend():
    with open(FRONTEND_ICONS, encoding="utf-8") as f:
        source = f.read()
    icon_map = re.search(r"map = \{(.*?)\};", source, re.S)
    assert icon_map
    frontend = re.findall(r'"([a-z0-9_]+)":', icon_map.group(1))
    assert list(known_item_icons()) == frontend, (
        "Regenerate backend/templates/item_icons.json with icons/generate-item-icons.py"
    )
