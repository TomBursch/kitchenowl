# Ingredient Detection

When scraping recipes from the web multiple strategies to map ingredients to household items are available.
The scraping only returns a list of ingredients (like `3 cloves garlic`, `1/2 teaspoon salt`, `2 carrots chopped`) from which we need to extract the ingredient name and description. The names are then mapped to existing household items.

The default method is to use a local [natural language processing (NLP) model](https://github.com/strangetom/ingredient-parser/) trained on English ingredients. To use this leave the `LLM_MODEL` environment variable empty.

Alternatively, you can use a [Large Language Model (LLM)](https://github.com/BerriAI/litellm), multiple models are supported. Using a LLM uses more resources but can provide better results, especially for languages other than English.
It can automatically translate the ingredient names to the household language for better item detection.

### OpenAI

To use OpenAi you need to set the following environment variables:

- `LLM_MODEL`: The model name (e.g. `gpt-3.5-turbo`)
- `OPENAI_API_KEY`: Your OpenAI API key

### Ollama

To use OpenAi you need to set the following environment variables:

- `LLM_MODEL`: The model name prefixed with `ollama` (e.g. `ollama/llama3.1`)
- `OPENAI_API_KEY`: Your OpenAI API key
- `LLM_API_URL`: The URL of the Ollama server (e.g. `http://localhost:11434`)
