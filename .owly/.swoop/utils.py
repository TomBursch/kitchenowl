import os
import re
import time
import logging
import requests

def load_recipe_urls(file_path: str) -> list:
    """
    Load recipe URLs from a JSON file. Expects a JSON array of URL strings.
    """
    import json
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            # The file might contain an object with a list or just a list
            if isinstance(data, dict):
                # e.g. {"recipes": ["url1", "url2", ...]}
                for value in data.values():
                    if isinstance(value, list):
                        return value
                return []
            elif isinstance(data, list):
                return data
            else:
                return []
    except FileNotFoundError:
        logging.error(f"URLs file not found: {file_path}")
        return []
    except Exception as e:
        logging.error(f"Error reading URLs from {file_path}: {e}")
        return []

def download_image(image_url: str, download_dir: str = "/data/upload/recipes", filename_prefix: str = None) -> str:
    """
    Download an image from the given URL into the specified directory.
    If filename_prefix is provided, uses it for naming the file (with extension).
    Returns the filename of the saved image, or None on failure.
    """
    if not image_url:
        return None
    os.makedirs(download_dir, exist_ok=True)
    # Determine file extension from URL or content-type
    ext = ".jpg"
    url_path = image_url.split("?")[0]
    for candidate in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
        if url_path.lower().endswith(candidate):
            ext = candidate if candidate.startswith('.') else f".{candidate}"
            break
    try:
        resp = requests.get(image_url, timeout=15)
        resp.raise_for_status()
    except Exception as e:
        logging.error(f"Failed to download image from {image_url}: {e}")
        return None
    # Adjust extension if content-type suggests a different image format
    content_type = resp.headers.get("Content-Type", "").lower()
    if "image/" in content_type:
        if "jpeg" in content_type or "jpg" in content_type:
            ext = ".jpg"
        elif "png" in content_type:
            ext = ".png"
        elif "gif" in content_type:
            ext = ".gif"
        elif "webp" in content_type:
            ext = ".webp"
    # Use provided prefix or current timestamp for filename
    if not filename_prefix:
        filename_prefix = str(int(time.time()))
    filename = filename_prefix + ext
    file_path = os.path.join(download_dir, filename)
    try:
        with open(file_path, "wb") as f:
            f.write(resp.content)
    except Exception as e:
        logging.error(f"Error saving image to {file_path}: {e}")
        return None
    return filename

def parse_ingredient(ingredient: str) -> tuple:
    """
    Parse a single ingredient string into (item_name, amount_description, optional_flag).
    - item_name: the core ingredient name (in English).
    - amount_description: the quantity and unit part (and any notes) as a string.
    - optional_flag: boolean indicating if the ingredient is marked optional.
    """
    ing = ingredient.strip()
    optional = False
    # Detect "(optional)" or "optional" at end
    if ing.lower().endswith("(optional)"):
        optional = True
        ing = ing[: -len("(optional)")].strip()
    elif ing.lower().endswith(" optional"):
        optional = True
        ing = ing[: -len(" optional")].rstrip(",() ").strip()
    # Separate any "plus ..." notes (e.g. "plus extra for dusting")
    plus_note = None
    if " plus " in ing:
        parts = ing.split(" plus ", 1)
        ing = parts[0].strip()
        plus_note = parts[1].strip()
        if plus_note.lower().startswith("and "):
            plus_note = plus_note[4:].strip()
    # Extract parenthetical notes (e.g. package sizes) and remove them from main string
    paren_notes = []
    if "(" in ing and ")" in ing:
        matches = re.findall(r'\([^)]*\)', ing)
        for m in matches:
            note = m.strip("()").strip()
            if note:
                paren_notes.append(note)
        ing = re.sub(r'\([^)]*\)', '', ing)
        ing = re.sub(r'\s+', ' ', ing).strip()
    # Known units and descriptors
    units = {"teaspoon","teaspoons","tbsp","tablespoon","tablespoons","cup","cups",
             "ounce","ounces","oz","gram","grams","g","kilogram","kilograms","kg",
             "liter","liters","l","ml","clove","cloves","pint","pints","quart","quarts",
             "gallon","gallons","can","cans","package","packages","pkg",
             "slice","slices","piece","pieces","pinch","pinches","dash","dashes","head","heads"}
    numeric_words = {"one","two","three","four","five","six","seven","eight","nine","ten","half","quarter"}
    size_words = {"small","medium","large","big","extra-large","extra large","extra"}
    adjectives = {"fresh","dried","ground","minced","chopped","finely","thinly","sliced","crumbled"}
    item_name = ""
    amount_desc = None

    # Split the ingredient into tokens for analysis
    tokens = ing.split()
    if not tokens:
        return (ing, None, optional)
    # Identify leading quantity (numeric or fraction) and unit
    qty_val = None
    qty_str = None
    used_unit = None

    # Check for combined number+unit token (e.g., "200g")
    first_token = tokens[0]
    if re.match(r'^\d+(\.\d+)?[A-Za-z]+$', first_token):
        # Separate numeric part and unit part
        num_match = re.match(r'^(\d+(\.\d+)?)', first_token)
        unit_match = re.match(r'^\d+(\.\d+)?([A-Za-z]+)$', first_token)
        if num_match and unit_match:
            qty_str = num_match.group(1)
            used_unit = unit_match.group(2)
        tokens = tokens[1:]  # remove the first token
    # Check for standalone fraction at start (e.g., "1/2")
    if qty_str is None and re.match(r'^\d+/\d+', tokens[0] if tokens else ""):
        frac = tokens[0]
        tokens = tokens[1:]
        qty_str = frac

    # Check for separate numeric quantity at start
    if qty_str is None and tokens:
        match = re.match(r'^(\d+(\.\d+)?)(?:$|\s)', tokens[0])
        if match:
            qty_str = match.group(1)
            tokens = tokens[1:]
    # If quantity string is found, convert to float value
    if qty_str:
        try:
            # Handle mixed fraction (e.g., "1 1/2")
            total = 0.0
            for part in qty_str.split():
                if part.lower() in numeric_words:
                    # convert words to numbers
                    word_map = {"half": 0.5, "quarter": 0.25,
                                "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
                                "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10}
                    total += word_map.get(part.lower(), 0)
                elif '/' in part:
                    num, den = part.split('/')
                    total += float(num) / float(den)
                else:
                    total += float(part)
            qty_val = total if total != 0 else None
        except Exception:
            qty_val = None
    # If no explicit numeric quantity, check if first token is a word like "a", "some", etc.
    if qty_val is None and qty_str is None and tokens:
        if tokens[0].lower() in ["a", "an", "some"]:
            # Treat "a/an/some" as an indefinite 1.0 quantity (for formatting purposes)
            qty_val = 1.0
            tokens = tokens[1:]
            if tokens and tokens[0].lower() == "of":
                tokens = tokens[1:]
    # Determine formatted quantity string (with one decimal place)
    qty_formatted = None
    if qty_val is not None:
        if abs(qty_val - int(qty_val)) < 1e-6:
            qty_formatted = f"{int(qty_val)}.0"
        else:
            qty_formatted = f"{qty_val:.1f}"
    # Build the amount description (quantity + unit + descriptors)
    desc_parts = []
    if qty_formatted:
        desc_parts.append(qty_formatted)
    if tokens and tokens[0].lower() in units:
        used_unit = tokens[0]
        tokens = tokens[1:]
        # remove leading 'of' after a unit (e.g., "1 cup of sugar")
        if tokens and tokens[0].lower() == "of":
            tokens = tokens[1:]
    if used_unit:
        desc_parts.append(used_unit)
    # Handle any size/adjective words following the unit/quantity
    while tokens and (tokens[0].lower() in size_words or tokens[0].lower() in adjectives):
        # Combine "extra large" into one descriptor
        if len(tokens) > 1 and tokens[0].lower() == "extra" and tokens[1].lower() == "large":
            desc_parts.append("extra large")
            tokens = tokens[2:]
        else:
            desc_parts.append(tokens[0])
            tokens = tokens[1:]
    # Now the remaining tokens (if any) should form the item name (and possibly trailing notes)
    remaining = " ".join(tokens).strip()
    trailing_note = ""
    if remaining:
        # If there's a comma, treat the part after comma as a note (e.g., preparation method)
        if "," in remaining:
            main_part, note_part = remaining.split(",", 1)
            remaining = main_part.strip()
            trailing_note = note_part.strip()
        # Check for specific trailing phrases to move to note (e.g., "to taste", "divided")
        end_phrases = ["to taste", "to serve", "for garnish", "for serving", "divided"]
        for phrase in end_phrases:
            if remaining.lower().endswith(phrase):
                remaining = remaining[: -len(phrase)].strip()
                trailing_note = (phrase if not trailing_note else trailing_note + " " + phrase).strip()
    item_name = remaining if remaining else ""
    # Append trailing notes and parenthetical/plus notes to description
    if trailing_note:
        desc_parts.append(trailing_note)
    if paren_notes:
        desc_parts.append("(" + "; ".join(paren_notes) + ")")
    if plus_note:
        desc_parts.append("(" + plus_note + ")")
    # Finalize amount description string
    amount_desc = " ".join(desc_parts).strip() if desc_parts else None
    # Normalize item_name spacing and minor plural forms
    item_name = item_name.strip()
    if item_name.lower() == "cloves":
        item_name = "clove"
    if item_name.lower().endswith(" cloves"):
        item_name = item_name[:-7] + " clove"
    return (item_name or "", amount_desc, optional)
