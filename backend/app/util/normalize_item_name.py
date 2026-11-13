import unicodedata

LIGATURE_MAP = str.maketrans(
    {
        "æ": "ae",
        "Æ": "AE",
        "œ": "oe",
        "Œ": "OE",
        "ĳ": "ij",
        "Ĳ": "IJ",
        "ø": "o",
        "Ø": "O",
        "ß": "ss",
        "ẞ": "SS",
        "ð": "d",
        "Ð": "D",
        "þ": "th",
        "Þ": "TH",
        "ł": "l",
        "Ł": "L",
        "đ": "d",
        "Đ": "D",
        "ħ": "h",
        "Ħ": "H",
        "ŧ": "t",
        "Ŧ": "T",
        "ǥ": "g",
        "Ǥ": "G",
        "ƀ": "b",
        "Ƀ": "B",
        "ŋ": "ng",
        "Ŋ": "NG",
        "ı": "i",
        "İ": "I",
        "ĸ": "k",
        "ŉ": "n",
        "ƕ": "hv",
        "Ƕ": "HV",
        "ƣ": "oi",
        "Ƣ": "OI",
        "ȣ": "ou",
        "Ȣ": "OU",
        "ə": "e",
        "Ə": "E",
    }
)


def unaccent(text: str | None) -> str | None:
    if text is None:
        return None
    normalized = unicodedata.normalize("NFKD", text)
    stripped = "".join(ch for ch in normalized if not unicodedata.combining(ch))
    return stripped.translate(LIGATURE_MAP)
