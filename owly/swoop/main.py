import os
import logging

# Local module imports
import scraper
import normalizer
import utils
import db

def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")
    # Load recipe URLs
    urls_file = os.getenv("URLS_FILE", "recipe_urls.json")
    recipe_urls = utils.load_recipe_urls(urls_file)
    if not recipe_urls:
        logging.error("No recipe URLs found to process. Make sure the JSON file is present and valid.")
        return

    # Connect to the database
    try:
        conn = db.get_connection()
    except Exception as e:
        logging.error("Could not connect to the database. Exiting.")
        return

    for url in recipe_urls:
        url = url.strip()
        if not url:
            continue
        logging.info(f"Processing recipe URL: {url}")
        # Scrape the recipe data
        recipe_data = scraper.scrape_recipe(url)
        if not recipe_data or not recipe_data.get("title"):
            logging.error(f"Skipping URL (scrape failed or no title): {url}")
            continue
        title = recipe_data["title"].strip()
        if title == "":
            logging.error(f"Skipping URL (empty title): {url}")
            continue

        # Check for duplicate recipe title before heavy processing
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM recipes WHERE household_id=%s AND LOWER(name)=LOWER(%s)", (db.HOUSEHOLD_ID, title))
            if cur.fetchone():
                logging.info(f"Recipe '{title}' already exists in DB, skipping.")
                continue

        ingredients = recipe_data.get("ingredients", [])
        instructions = recipe_data.get("instructions", "")
        # Normalize ingredients and instructions using OpenAI
        try:
            ingredients_norm = normalizer.normalize_ingredients(ingredients)
            instructions_norm = normalizer.normalize_instructions(instructions)
        except Exception as e:
            logging.error(f"Normalization failed for '{title}' (using original data): {e}")
            ingredients_norm = ingredients
            instructions_norm = instructions

        # Parse normalized ingredients into structured form
        parsed_ingredients = []
        for ing in ingredients_norm:
            item_name, amount_desc, optional_flag = utils.parse_ingredient(ing)
            parsed_ingredients.append((item_name, amount_desc, optional_flag))

        # Determine source (domain name) for reference
        source = ""
        try:
            from urllib.parse import urlparse
            netloc = urlparse(url).netloc
            source = netloc or ""
        except Exception:
            source = ""

        # Insert recipe and ingredients into the database
        recipe_id = db.insert_recipe(conn, title, instructions_norm, parsed_ingredients, source=source)
        if not recipe_id:
            # Insertion failed or skipped (duplicate)
            continue

        # Download recipe image if available
        image_url = recipe_data.get("image_url")
        if image_url:
            filename = utils.download_image(image_url, download_dir="/data/upload/recipes", filename_prefix=str(recipe_id))
            if filename:
                # Update the recipe record with the image filename
                with conn.cursor() as cur:
                    cur.execute("UPDATE recipes SET image=%s WHERE id=%s", (f"recipes/{filename}", recipe_id))
                conn.commit()
                logging.info(f"Downloaded image for recipe '{title}' and updated record.")
            else:
                logging.warning(f"Failed to download image for '{title}'. Proceeding without image.")

    # Close the database connection
    conn.close()
    logging.info("Recipe import process completed.")

if __name__ == "__main__":
    main()
