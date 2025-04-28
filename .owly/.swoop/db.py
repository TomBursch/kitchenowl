import os
import logging
import psycopg2

# Read database connection settings from environment
DB_HOST = os.getenv("DB_HOST", "")
DB_PORT = os.getenv("DB_PORT", "")
DB_NAME = os.getenv("DB_NAME", "")
DB_USER = os.getenv("DB_USER", "")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
# Household ID to use (defaults to 1 if not set)
HOUSEHOLD_ID = int(os.getenv("HOUSEHOLD_ID", "1") or "1")

def get_connection():
    """Establish a connection to the Postgres database using environment variables."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT or 5432,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        # Disable autocommit to manage transactions manually
        conn.autocommit = False
        return conn
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        raise

def insert_recipe(conn, title: str, instructions: str, ingredients: list, source: str = "", image_name: str = None) -> int:
    """
    Insert a new recipe and its ingredients into the database.
    - title: recipe title
    - instructions: normalized instructions text
    - ingredients: list of tuples (item_name, amount_desc, optional_flag) for each ingredient
    - source: source reference (e.g., URL or site name) to store in the recipe's source field
    - image_name: filename of the downloaded image (if any), to link to the recipe
    Returns the new recipe ID on success, or None on failure/duplicate.
    """
    try:
        with conn.cursor() as cur:
            # Check for existing recipe with the same title (case-insensitive) in the same household
            cur.execute("SELECT id FROM recipes WHERE household_id=%s AND LOWER(name)=LOWER(%s)", (HOUSEHOLD_ID, title))
            if cur.fetchone():
                logging.info(f"Duplicate recipe skipped: '{title}' already exists.")
                return None
            # Insert into recipes table
            cur.execute(
                """INSERT INTO recipes (household_id, name, description, source, public,
                                         time, cook_time, prep_time, yields, created_at, updated_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                   RETURNING id""",
                (HOUSEHOLD_ID, title, instructions, source, False, 0.0, 0, 0, 0.0)
            )
            recipe_id = cur.fetchone()[0]
            # Insert each ingredient
            for (item_name, amount_desc, optional_flag) in ingredients:
                if not item_name:
                    # Skip if no item name parsed
                    continue
                # Check if item already exists in this household (by name)
                cur.execute("SELECT id FROM items WHERE household_id=%s AND LOWER(name)=LOWER(%s)", (HOUSEHOLD_ID, item_name))
                row = cur.fetchone()
                if row:
                    item_id = row[0]
                else:
                    # Insert new item into items table
                    cur.execute(
                        "INSERT INTO items (household_id, name, created_at, updated_at) VALUES (%s, %s, NOW(), NOW()) RETURNING id",
                        (HOUSEHOLD_ID, item_name)
                    )
                    item_id = cur.fetchone()[0]
                # Avoid linking the same item twice for one recipe
                cur.execute("SELECT 1 FROM recipe_items WHERE recipe_id=%s AND item_id=%s", (recipe_id, item_id))
                if cur.fetchone():
                    continue  # already linked (skip duplicates in the same recipe)
                # Insert into recipe_items (link table with amount and optional flag)
                cur.execute(
                    "INSERT INTO recipe_items (recipe_id, item_id, description, optional, created_at, updated_at) VALUES (%s, %s, %s, %s, NOW(), NOW())",
                    (recipe_id, item_id, amount_desc or "", optional_flag)
                )
            # Update recipe with image filename if provided
            if image_name:
                cur.execute("UPDATE recipes SET image=%s WHERE id=%s", (f"recipes/{image_name}", recipe_id))
        conn.commit()
        logging.info(f"Inserted recipe '{title}' (ID: {recipe_id}) with {len(ingredients)} ingredients.")
        return recipe_id
    except Exception as e:
        conn.rollback()
        logging.error(f"Error inserting recipe '{title}': {e}")
        return None
