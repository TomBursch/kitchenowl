import os
import logging
import openai

# Configure OpenAI API
openai.api_key = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")

def normalize_ingredients(ingredients: list) -> list:
    """
    Use OpenAI API to normalize a list of ingredient strings to English with standardized units/format.
    Returns a new list of ingredient strings.
    """
    if not openai.api_key:
        logging.warning("OpenAI API key not set. Skipping ingredient normalization.")
        return ingredients
    if not ingredients:
        return ingredients

    prompt = (
        "Normalize the following list of recipe ingredients. "
        "Translate to English if necessary and standardize units and wording. "
        "Provide the output as one ingredient per line (no bullets or numbering):\n"
        + "\n".join(ingredients)
    )
    try:
        # Make OpenAI API call with retry logic
        for attempt in range(3):
            try:
                response = openai.ChatCompletion.create(
                    model=OPENAI_MODEL,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0
                )
                normalized_text = response["choices"][0]["message"]["content"]
                break  # success
            except Exception as e:
                logging.warning(f"OpenAI ingredient normalization failed (attempt {attempt+1}): {e}")
                if attempt == 2:
                    raise
        # Split the response by lines into a list, ignoring empty lines
        normalized_list = [line.strip() for line in normalized_text.splitlines() if line.strip()]
        return normalized_list if normalized_list else ingredients
    except Exception as e:
        logging.error(f"Failed to normalize ingredients via OpenAI: {e}")
        return ingredients

def normalize_instructions(instructions: str) -> str:
    """
    Use OpenAI API to normalize (translate/standardize) recipe instructions to English.
    Returns the normalized instructions text.
    """
    if not openai.api_key:
        logging.warning("OpenAI API key not set. Skipping instructions normalization.")
        return instructions
    if not instructions:
        return instructions

    prompt = (
        "Translate and normalize the following recipe instructions to clear English. "
        "Preserve the step separation (use new lines to separate steps):\n"
        + instructions
    )
    try:
        for attempt in range(3):
            try:
                response = openai.ChatCompletion.create(
                    model=OPENAI_MODEL,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0
                )
                normalized_text = response["choices"][0]["message"]["content"]
                break
            except Exception as e:
                logging.warning(f"OpenAI instructions normalization failed (attempt {attempt+1}): {e}")
                if attempt == 2:
                    raise
        normalized = normalized_text.strip()
        return normalized if normalized else instructions
    except Exception as e:
        logging.error(f"Failed to normalize instructions via OpenAI: {e}")
        return instructions
