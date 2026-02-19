## Contributing

Take a look at the general contribution rules [here](../CONTRIBUTING.md).

### Requirements
- Python 3.12+
- [UV](https://docs.astral.sh/uv/getting-started/)

### Setup & Install
- If you haven't already, switch to the backend folder `cd backend`
- Install dependencies with `uv sync`
- Install the pre-commit hooks `uv run pre-commit install`
- Optionally: Activate your python environment `source .venv/bin/activate` (allows you to omit `uv run` in the following steps, environment can be deactivated with `deactivate`)
- Initialize/Upgrade requirements for the recipe scraper `uv run python -c "import nltk; nltk.download('averaged_perceptron_tagger_eng', download_dir='.venv/nltk_data')"`
- Initialize/Upgrade the SQLite database with `uv run flask db upgrade`
- Run debug server with `uv run wsgi.py`
- The backend should be reachable at `localhost:5000`
- For some simple interactions with the backend (like adding a user), you can use `uv run manage.py`

### MCP server (experimental)
A lightweight MCP bridge is available in `mcp_server.py`.

Run:
- `uv run python mcp_server.py`

Environment variables:
- `KITCHENOWL_API_URL` (default: `http://127.0.0.1:5000/api`)
- `KITCHENOWL_BEARER_TOKEN` (JWT token for authenticated endpoints)

Current tools:
- `health`
- `list_households`
- `list_shoppinglists`
- `list_shoppinglist_items`
- `list_items`
- `create_item`
- `list_recipes`
- `search_recipes`
- `create_shoppinglist`
- `update_shoppinglist`
- `delete_shoppinglist`
- `add_item_by_name`
- `remove_item`
- `update_item_description`
- `create_recipe`
- `update_recipe`
- `delete_recipe`
- `list_expenses`
- `get_expense`
- `create_expense`
- `update_expense`
- `delete_expense`
- `expense_overview`
- `expense_categories`
- `create_expense_category`
- `update_expense_category`
- `delete_expense_category`
