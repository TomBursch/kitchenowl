import logging
from recipe_scrapers import scrape_me

def scrape_recipe(url: str) -> dict:
    """
    Scrape the recipe data from the given URL using recipe-scrapers.
    Returns a dictionary with keys: title, ingredients, instructions, image_url,
    total_time, prep_time, cook_time, yields. Returns None on failure.
    """
    try:
        # Initialize the scraper for the URL (auto-detects site)
        scraper = scrape_me(url)
    except Exception as e:
        logging.error(f"Scraper initialization failed for {url}: {e}")
        return None

    data = {}
    try:
        data["title"] = scraper.title()
    except Exception:
        data["title"] = None
    try:
        data["ingredients"] = scraper.ingredients()  # list of ingredient strings
    except Exception:
        data["ingredients"] = []
    try:
        data["instructions"] = scraper.instructions()  # full instructions as one string
    except Exception:
        data["instructions"] = ""
    try:
        data["image_url"] = scraper.image()
    except Exception:
        data["image_url"] = None
    # Optional fields: handle missing data gracefully
    try:
        data["total_time"] = scraper.total_time() or 0
    except Exception:
        data["total_time"] = 0
    try:
        data["prep_time"] = scraper.prep_time() or 0
    except Exception:
        data["prep_time"] = 0
    try:
        data["cook_time"] = scraper.cook_time() or 0
    except Exception:
        data["cook_time"] = 0
    try:
        # Yields might be a string like "4 servings" – attempt to extract a number
        raw_yields = scraper.yields()
        if raw_yields:
            # Extract leading number from yields (e.g., "4 servings" -> 4.0)
            import re
            match = re.match(r"^(\d+)", str(raw_yields))
            data["yields"] = float(match.group(1)) if match else 0.0
        else:
            data["yields"] = 0.0
    except Exception:
        data["yields"] = 0.0

    return data
