# MCP Server

KitchenOwl includes a [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server. It lets MCP clients and AI assistants (Claude, ChatGPT, Cursor, Open WebUI, …) read from and write to your KitchenOwl instance: shopping lists, items, recipes, tags, the meal plan and expenses.

The MCP endpoint lives next to the REST API and uses the same accounts: everything an MCP client does is limited to the households the authenticated user belongs to.

## Enabling the MCP server

The MCP endpoint is disabled by default. Set `KITCHENOWL_MCP_ENABLED=true` on the backend container:

```yml
services:
  back:
    image: tombursch/kitchenowl-backend:latest
    environment:
      - JWT_SECRET_KEY=PLEASE_CHANGE_ME
      - KITCHENOWL_MCP_ENABLED=true
```

The server is then reachable at `https://<your-kitchenowl-instance>/mcp`. If you run the standard setup with the `tombursch/kitchenowl-web` frontend container, `/mcp` is already proxied to the backend with buffering disabled, so no reverse-proxy changes are needed. When you host the backend behind your own proxy, make sure streaming responses are not buffered (see [Reverse Proxy](../self-hosting/reverse-proxy.md)).

## Authentication

The MCP server authenticates requests with a regular KitchenOwl JWT access token, exactly like the [REST API](./API.md). Obtain a token by logging in:

```bash
curl -s -X POST https://your-kitchenowl.example.org/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "secret"}' | jq -r .access_token
```

and send it as a bearer token with every MCP request:

```
Authorization: Bearer <access_token>
```

!!! warning
    The token grants full write access to all your households. Only give it to clients you trust, and log out the session (or rotate `JWT_SECRET_KEY`) if you no longer need it. Access tokens expire together with the refresh token lifetime (`JWT_REFRESH_TOKEN_EXPIRES`, default 30 days).

## Transports & protocol versions

Two HTTP transports are implemented:

- **Streamable HTTP** (recommended): send JSON-RPC requests to `POST /mcp`. The endpoint is stateless, so it works reliably behind load-balanced or multi-worker setups. `GET` and `DELETE` on `/mcp` return `405`, which the spec allows.
- **HTTP+SSE** (legacy): open `GET /mcp/sse` to receive a session `endpoint` event, then send JSON-RPC requests to `POST /mcp/messages?session_id=…`; replies arrive over the SSE stream (with keep-alive comments every 15 seconds). Sessions live in a single worker process, so prefer the streamable transport wherever possible.

Supported protocol versions: `2025-06-18`, `2025-03-26` and `2024-11-05`. An `initialize` request with a different (or missing) version is answered with the latest supported version.

## Trying it out with curl

!!! example "Initialize"
    ```bash
    TOKEN=$(curl -s -X POST https://your-kitchenowl.example.org/api/auth \
      -H "Content-Type: application/json" \
      -d '{"username": "alice", "password": "secret"}' | jq -r .access_token)

    curl -s -X POST https://your-kitchenowl.example.org/mcp \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
          "protocolVersion": "2025-06-18",
          "capabilities": {},
          "clientInfo": { "name": "curl", "version": "0.0.1" }
        }
      }' | jq
    ```

!!! example "List tools"
    ```bash
    curl -s -X POST https://your-kitchenowl.example.org/mcp \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}' | jq
    ```

!!! example "Call a tool"
    ```bash
    # Nearly every tool is household-scoped, so start by listing households
    curl -s -X POST https://your-kitchenowl.example.org/mcp \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": { "name": "list_households", "arguments": {} }
      }' | jq
    ```

## Connecting an MCP client

Clients that speak MCP over HTTP (Open WebUI, Continue, …) can be pointed directly at `https://<your-kitchenowl-instance>/mcp` with the `Authorization: Bearer <access_token>` header.

Clients that only support stdio servers (such as Claude Desktop) can use [`mcp-remote`](https://github.com/modelcontextprotocol/mcp-remote) as a bridge:

```json
{
  "mcpServers": {
    "kitchenowl": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://your-kitchenowl.example.org/mcp",
        "--header",
        "Authorization: Bearer <access_token>"
      ]
    }
  }
}
```

## Implemented tools

All tools return JSON, both as readable text content and as `structuredContent`. Required arguments are listed first; optional ones in parentheses.

### Households

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_households` | – | List all households the authenticated user is a member of. Start here: the returned `household_id` is needed by almost every other tool. |

### Shopping lists

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_shoppinglists` | `household_id` | List all shopping lists of a household. |
| `list_shoppinglist_items` | `list_id` | List the items currently on a shopping list. |
| `create_shoppinglist` | `household_id`, `name` | Create a new shopping list. |
| `delete_shoppinglist` | `list_id` | Delete a shopping list. The default list cannot be deleted. |
| `add_item_by_name` | `list_id`, `name` (`description`) | Add an item to a shopping list by name, creating the item if it does not exist yet. |
| `remove_item_from_list` | `list_id` (`item_id` or `name`) | Remove an item from a shopping list by id or name. |

### Items

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_items` | `household_id` (`search`) | List household items, optionally filtered by a name search. Returns at most 100 items. |

### Recipes

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_recipes` | `household_id` (`offset`, `limit`, `additional_fields`) | List recipes as paginated `id`/`name` references. See [Behavior notes](#behavior-notes). |
| `search_recipes` | `household_id`, `query` (`offset`, `limit`, `additional_fields`) | Search recipe names (case-insensitive substring match), paginated like `list_recipes`. |
| `get_recipe` | `recipe_id` | Get one full recipe, including description, ingredients and tags. |
| `create_recipe` | `household_id`, `name` (`description`, `time`, `cook_time`, `prep_time`, `yields`, `source`, `visibility`, `items`, `tags`) | Create a recipe. `items` accepts plain names or `{name, description, optional}` objects; `tags` a list of tag names. Missing items and tags are created automatically. |
| `update_recipe` | `recipe_id` (`name`, `description`, `time`, `cook_time`, `prep_time`, `yields`, `source`, `visibility`) | Update the given fields of a recipe. Times are in minutes, `visibility` is `0` (private), `1` (link) or `2` (public). |
| `delete_recipe` | `recipe_id` | Delete a recipe. |
| `add_recipe_item` | `recipe_id`, `name` (`description`, `optional`) | Add (or update) an ingredient on a recipe, creating the item if needed. |
| `remove_recipe_item` | `recipe_id`, `item_id` | Remove an ingredient from a recipe. |
| `add_recipe_tag` | `recipe_id`, `name` | Add a tag to a recipe, creating the tag if needed. |
| `remove_recipe_tag` | `recipe_id` (`tag_id` or `name`) | Remove a tag from a recipe. |
| `scrape_recipe` | `household_id`, `url` | Scrape a recipe from a website and return it (without saving). Only supported websites work; anything else returns an "Unsupported website" error. |

### Tags

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_tags` | `household_id` | List all tags of a household. |
| `create_tag` | `household_id`, `name` | Create a tag (returns the existing tag if the name is already used). |

### Meal plan

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_planner` | `household_id` | List all meal plan entries of a household. |
| `add_planner_entry` | `household_id`, `recipe_id`, `cooking_date` (`yields`) | Plan a recipe for a day. `cooking_date` is an ISO 8601 datetime, e.g. `2026-11-08T00:00:00Z`. |
| `remove_planner_entry` | `household_id`, `recipe_id`, `cooking_date` | Remove a meal plan entry matching recipe and date. |

### Expenses

| Tool | Arguments | Description |
| --- | --- | --- |
| `list_expenses` | `household_id` (`search`) | List the most recent expenses (up to 50), optionally filtered by name. |
| `create_expense` | `household_id`, `name`, `amount` (`description`, `date`) | Record an expense paid by the authenticated user. `date` is an ISO 8601 datetime and defaults to now. |
| `delete_expense` | `expense_id` | Delete an expense. |

## Behavior notes

- **Household scoping**: every mutation and read is checked against the households of the authenticated user. Requests for households you do not belong to fail with a not-found error, as do resources of other households.
- **Recipe discovery**: `list_recipes` and `search_recipes` return only `id` and `name` by default to keep responses small. Pass `additional_fields` to request more data in bulk: `description`, `photo`, `photo_hash`, `time`, `cook_time`, `prep_time`, `yields`, `source`, `visibility`, `created_at`, `updated_at`, `planned`, `planned_days`, `planned_cooking_dates`, `items` and `tags`. Pagination uses `offset`/`limit` (default 50, maximum 100); the response contains `total` and `next_offset` (`null` when the last page was returned). Use `get_recipe` for one complete recipe.
- **Idempotency**: adding an item, tag or planner entry that already exists does not duplicate it; the existing entry is kept or updated.
- **Errors** are reported as JSON-RPC errors (invalid arguments, unknown tool) or as a tool result with a reason, e.g. `{ "removed": false, "reason": "not_found" }` or `{ "deleted": false, "reason": "default_list" }`.
