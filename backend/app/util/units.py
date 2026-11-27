"""Unit vocabulary shared by the description splitter and merger."""

# The word units outrank the SI ones so that "lb" and "pt" are not read as a
# litre followed by a stray letter.
TERMINALS = r"""
COUNT.5: "x"i
SI_WEIGHT.5: "mg"i | "g"i | "kg"i
SI_VOLUME.5: "ml"i | "l"i
IMPERIAL_WEIGHT.6: /(?:oz|lbs?)\b/i
IMPERIAL_VOLUME.6: /(?:tsps?|tbsps?|fl\s?oz|cups?|pts?|qts?)\b/i
PACKAGING.6: /(?:packs?|packets?|bags?|tins?|cans?|jars?|bottles?|bunch(?:es)?|box(?:es)?|punnets?|dozen)\b/i
"""

NAMED = "COUNT | SI_WEIGHT | SI_VOLUME | IMPERIAL_WEIGHT | IMPERIAL_VOLUME | PACKAGING"

# Units spelled as words read better separated from the number: "3 tins", but
# "500g".
SPACED = {"DESCRIPTION", "IMPERIAL_WEIGHT", "IMPERIAL_VOLUME", "PACKAGING"}

# Units whose plural spelling should merge with the singular. Listed rather
# than derived because stripping a trailing s turns "bottles" into "bottl".
PLURALS = {
    "lbs": "lb",
    "tsps": "tsp",
    "tbsps": "tbsp",
    "cups": "cup",
    "pts": "pt",
    "qts": "qt",
    "packs": "pack",
    "packets": "packet",
    "bags": "bag",
    "tins": "tin",
    "cans": "can",
    "jars": "jar",
    "bottles": "bottle",
    "bunches": "bunch",
    "boxes": "box",
    "punnets": "punnet",
}


def canonical(unit: str) -> str:
    """Fold a unit to the spelling it should merge under."""
    value = unit.lower().strip().replace(" ", "")
    return PLURALS.get(value, value)
