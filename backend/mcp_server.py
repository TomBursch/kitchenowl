#!/usr/bin/env python3
"""KitchenOwl MCP server (HTTP bridge to KitchenOwl REST API).

Env:
- KITCHENOWL_API_URL (default: http://127.0.0.1:5000/api)
- KITCHENOWL_BEARER_TOKEN (required for authenticated endpoints)
"""

from __future__ import annotations

import os
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP

API_URL = os.getenv("KITCHENOWL_API_URL", "http://127.0.0.1:5000/api").rstrip("/")
API_TOKEN = os.getenv("KITCHENOWL_BEARER_TOKEN", "")

mcp = FastMCP("kitchenowl")


class KitchenOwlApiError(RuntimeError):
    pass


def _headers() -> dict[str, str]:
    headers = {"Accept": "application/json"}
    if API_TOKEN:
        headers["Authorization"] = f"Bearer {API_TOKEN}"
    return headers


def _request(method: str, path: str, *, params: dict[str, Any] | None = None, json: dict[str, Any] | None = None) -> Any:
    url = f"{API_URL}/{path.lstrip('/')}"
    response = requests.request(method, url, headers=_headers(), params=params, json=json, timeout=20)
    if response.status_code >= 400:
        raise KitchenOwlApiError(f"{response.status_code} {response.reason}: {response.text[:500]}")
    if not response.content:
        return {"ok": True}
    return response.json()


@mcp.tool()
def health() -> dict[str, Any]:
    """Check KitchenOwl health endpoint and current MCP config."""
    payload = _request("GET", "/health")
    return {
        "api_url": API_URL,
        "token_configured": bool(API_TOKEN),
        "health": payload,
    }


@mcp.tool()
def list_households() -> Any:
    """List households available for current user/token."""
    return _request("GET", "/household")


@mcp.tool()
def list_shoppinglists(household_id: int, recent_limit: int = 8) -> Any:
    """List shopping lists for a household."""
    return _request("GET", f"/household/{household_id}/shoppinglist", params={"recent_limit": recent_limit})


@mcp.tool()
def list_shoppinglist_items(list_id: int) -> Any:
    """List items for a shopping list."""
    return _request("GET", f"/shoppinglist/{list_id}/items")


@mcp.tool()
def list_items(household_id: int, query: str) -> Any:
    """Search items in household by name."""
    return _request("GET", f"/household/{household_id}/item/search", params={"query": query})


@mcp.tool()
def create_item(household_id: int, name: str) -> Any:
    """Create item in household."""
    return _request("POST", f"/household/{household_id}/item", json={"name": name})


@mcp.tool()
def list_recipes(household_id: int) -> Any:
    """List recipes for a household."""
    return _request("GET", f"/household/{household_id}/recipe")


@mcp.tool()
def search_recipes(household_id: int, query: str, page: int = 0) -> Any:
    """Search recipes in household by name."""
    return _request(
        "GET",
        f"/household/{household_id}/recipe/search",
        params={"query": query, "page": page},
    )


@mcp.tool()
def create_shoppinglist(household_id: int, name: str) -> Any:
    """Create a shopping list in selected household."""
    return _request("POST", f"/household/{household_id}/shoppinglist", json={"name": name})


@mcp.tool()
def update_shoppinglist(list_id: int, name: str) -> Any:
    """Rename shopping list."""
    return _request("POST", f"/shoppinglist/{list_id}", json={"name": name})


@mcp.tool()
def delete_shoppinglist(list_id: int) -> Any:
    """Delete shopping list."""
    return _request("DELETE", f"/shoppinglist/{list_id}")


@mcp.tool()
def add_item_by_name(list_id: int, name: str, description: str = "") -> Any:
    """Add item to shopping list by name (creates item if missing)."""
    payload = {"name": name}
    if description:
        payload["description"] = description
    return _request("POST", f"/shoppinglist/{list_id}/add-item-by-name", json=payload)


@mcp.tool()
def remove_item(list_id: int, item_id: int) -> Any:
    """Remove item from shopping list (marks as done/removed)."""
    return _request("DELETE", f"/shoppinglist/{list_id}/item", json={"item_id": item_id})


@mcp.tool()
def update_item_description(list_id: int, item_id: int, description: str = "") -> Any:
    """Update/attach description for shopping list item."""
    return _request("POST", f"/shoppinglist/{list_id}/item/{item_id}", json={"description": description})


@mcp.tool()
def create_recipe(household_id: int, name: str, description: str = "") -> Any:
    """Create a basic recipe in household."""
    payload = {"name": name, "description": description}
    return _request("POST", f"/household/{household_id}/recipe", json=payload)


@mcp.tool()
def update_recipe(recipe_id: int, name: str | None = None, description: str | None = None) -> Any:
    """Update recipe (name/description subset)."""
    payload: dict[str, Any] = {}
    if name is not None:
        payload["name"] = name
    if description is not None:
        payload["description"] = description
    if not payload:
        raise KitchenOwlApiError("At least one of name/description must be provided")
    return _request("POST", f"/recipe/{recipe_id}", json=payload)


@mcp.tool()
def delete_recipe(recipe_id: int) -> Any:
    """Delete recipe by id."""
    return _request("DELETE", f"/recipe/{recipe_id}")


@mcp.tool()
def list_expenses(household_id: int, search: str | None = None) -> Any:
    """List expenses for household (latest first)."""
    params: dict[str, Any] = {}
    if search:
        params["search"] = search
    return _request("GET", f"/household/{household_id}/expense", params=params or None)


@mcp.tool()
def get_expense(expense_id: int) -> Any:
    """Get expense details by id."""
    return _request("GET", f"/expense/{expense_id}")


@mcp.tool()
def create_expense(
    household_id: int,
    name: str,
    amount: float,
    paid_by_id: int,
    paid_for_ids: list[int],
    description: str = "",
    category_id: int | None = None,
    date_ms: int | None = None,
) -> Any:
    """Create expense. paid_for_ids split equally (factor=1 each)."""
    if not paid_for_ids:
        raise KitchenOwlApiError("paid_for_ids cannot be empty")
    payload: dict[str, Any] = {
        "name": name,
        "amount": amount,
        "paid_by": {"id": paid_by_id},
        "paid_for": [{"id": uid, "factor": 1} for uid in paid_for_ids],
    }
    if description:
        payload["description"] = description
    if category_id is not None:
        payload["category"] = category_id
    if date_ms is not None:
        payload["date"] = date_ms
    return _request("POST", f"/household/{household_id}/expense", json=payload)


@mcp.tool()
def update_expense(
    expense_id: int,
    name: str | None = None,
    amount: float | None = None,
    description: str | None = None,
    category_id: int | None = None,
) -> Any:
    """Update expense basic fields."""
    payload: dict[str, Any] = {}
    if name is not None:
        payload["name"] = name
    if amount is not None:
        payload["amount"] = amount
    if description is not None:
        payload["description"] = description
    if category_id is not None:
        payload["category"] = category_id
    if not payload:
        raise KitchenOwlApiError("No fields provided for update")
    return _request("POST", f"/expense/{expense_id}", json=payload)


@mcp.tool()
def delete_expense(expense_id: int) -> Any:
    """Delete expense by id."""
    return _request("DELETE", f"/expense/{expense_id}")


@mcp.tool()
def expense_overview(household_id: int, frame: int = 2, steps: int = 5, page: int = 0) -> Any:
    """Get expense overview aggregates (default monthly frame)."""
    return _request(
        "GET",
        f"/household/{household_id}/expense/overview",
        params={"frame": frame, "steps": steps, "page": page},
    )


@mcp.tool()
def expense_categories(household_id: int) -> Any:
    """List expense categories for household."""
    return _request("GET", f"/household/{household_id}/expense/categories")


@mcp.tool()
def create_expense_category(household_id: int, name: str, color: int | None = None, budget: float | None = None) -> Any:
    """Create expense category."""
    payload: dict[str, Any] = {"name": name}
    if color is not None:
        payload["color"] = color
    if budget is not None:
        payload["budget"] = budget
    return _request("POST", f"/household/{household_id}/expense/categories", json=payload)


@mcp.tool()
def update_expense_category(category_id: int, name: str | None = None, color: int | None = None, budget: float | None = None) -> Any:
    """Update expense category."""
    payload: dict[str, Any] = {}
    if name is not None:
        payload["name"] = name
    if color is not None:
        payload["color"] = color
    if budget is not None:
        payload["budget"] = budget
    if not payload:
        raise KitchenOwlApiError("No fields provided for update")
    return _request("POST", f"/expense/categories/{category_id}", json=payload)


@mcp.tool()
def delete_expense_category(category_id: int) -> Any:
    """Delete expense category."""
    return _request("DELETE", f"/expense/categories/{category_id}")


if __name__ == "__main__":
    mcp.run()
