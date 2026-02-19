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
def list_recipes(household_id: int) -> Any:
    """List recipes for a household."""
    return _request("GET", f"/household/{household_id}/recipe")


if __name__ == "__main__":
    mcp.run()
