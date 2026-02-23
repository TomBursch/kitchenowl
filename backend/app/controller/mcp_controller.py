from __future__ import annotations

import json
import time
import uuid
from datetime import datetime
from typing import Any, Callable

from flask import Blueprint, Response, jsonify, request, stream_with_context
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.errors import NotFoundRequest
from app.models import (
    History,
    HouseholdMember,
    Item,
    Recipe,
    RecipeItems,
    RecipeTags,
    Shoppinglist,
    ShoppinglistItems,
    Expense,
    Planner,
    Tag,
)
from app.models.recipe import RecipeVisibility

mcp = Blueprint("mcp", __name__)


def _jsonrpc_ok(id_value: Any, result: Any):
    return jsonify({"jsonrpc": "2.0", "id": id_value, "result": result})


def _jsonrpc_err(id_value: Any, code: int, message: str):
    return jsonify({"jsonrpc": "2.0", "id": id_value, "error": {"code": code, "message": message}})


def _as_tool_result(payload: Any):
    text = json.dumps(payload, ensure_ascii=False, default=str)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": payload,
    }


def _require_household_access(household_id: int):
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if not member:
        raise NotFoundRequest()


def _tool_list_households(_args: dict[str, Any]) -> Any:
    members = HouseholdMember.find_by_user(current_user.id)
    return {"items": [m.household.obj_to_dict() for m in members]}


def _tool_list_shoppinglists(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    return {"items": [e.obj_to_dict() for e in Shoppinglist.all_from_household(household_id)]}


def _tool_list_shoppinglist_items(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()
    items = (
        ShoppinglistItems.query.filter(ShoppinglistItems.shoppinglist_id == list_id)
        .join(ShoppinglistItems.item)
        .all()
    )
    return {"items": [e.obj_to_item_dict() for e in items]}


def _tool_add_item_by_name(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    name = str(args["name"]).strip()
    description = str(args.get("description", ""))

    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item = Item.find_by_name(shoppinglist.household_id, name)
    if not item:
        item = Item.create_by_name(shoppinglist.household_id, name)

    con = ShoppinglistItems.find_by_ids(shoppinglist.id, item.id)
    if not con:
        con = ShoppinglistItems(description=description)
        con.created_by = current_user.id
        con.item = item
        con.shoppinglist = shoppinglist
        con.save()
        History.create_added(shoppinglist, item, description)

    return item.obj_to_dict()


def _tool_list_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    recipes = Recipe.query.filter(Recipe.household_id == household_id).order_by(Recipe.name).all()
    return {"items": [r.obj_to_full_dict() for r in recipes]}


def _tool_search_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    query = str(args["query"]).strip()
    _require_household_access(household_id)
    recipes = (
        Recipe.query.filter(Recipe.household_id == household_id)
        .filter(Recipe.name.ilike(f"%{query}%"))
        .order_by(Recipe.name)
        .limit(50)
        .all()
    )
    return [r.obj_to_full_dict() for r in recipes]


def _tool_list_expenses(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    search = str(args.get("search", "")).strip()
    _require_household_access(household_id)

    q = Expense.query.filter(Expense.household_id == household_id)
    if search:
        q = q.filter(Expense.name.ilike(f"%{search}%"))
    expenses = q.order_by(Expense.date.desc()).limit(50).all()
    return [e.obj_to_full_dict() for e in expenses]


def _tool_list_planner(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    plans = Planner.all_from_household(household_id)
    return [p.obj_to_full_dict() for p in plans]


TOOLS: dict[str, tuple[dict[str, Any], Callable[[dict[str, Any]], Any]]] = {
    "list_households": (
        {"type": "object", "properties": {}},
        _tool_list_households,
    ),
    "list_shoppinglists": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_shoppinglists,
    ),
    "list_shoppinglist_items": (
        {
            "type": "object",
            "properties": {"list_id": {"type": "integer"}},
            "required": ["list_id"],
        },
        _tool_list_shoppinglist_items,
    ),
    "add_item_by_name": (
        {
            "type": "object",
            "properties": {
                "list_id": {"type": "integer"},
                "name": {"type": "string"},
                "description": {"type": "string"},
            },
            "required": ["list_id", "name"],
        },
        _tool_add_item_by_name,
    ),
    "list_recipes": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_recipes,
    ),
    "search_recipes": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "query": {"type": "string"},
            },
            "required": ["household_id", "query"],
        },
        _tool_search_recipes,
    ),
    "list_expenses": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "search": {"type": "string"},
            },
            "required": ["household_id"],
        },
        _tool_list_expenses,
    ),
    "list_planner": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_planner,
    ),
}


@mcp.route("", methods=["GET"])
def mcp_info():
    return jsonify({"name": "KitchenOwl MCP endpoint", "transport": "jsonrpc-http", "methods": ["initialize", "tools/list", "tools/call"]})


@mcp.route("", methods=["POST"])
@jwt_required()
def mcp_post():
    body = request.get_json(silent=True) or {}
    id_value = body.get("id")
    method = body.get("method")
    params = body.get("params") or {}

    try:
        if method == "initialize":
            return _jsonrpc_ok(
                id_value,
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "kitchenowl-mcp", "version": "0.1.0"},
                },
            )

        if method == "notifications/initialized":
            return ("", 204)

        if method == "ping":
            return _jsonrpc_ok(id_value, {})

        if method == "tools/list":
            tools = []
            for name, (schema, _) in TOOLS.items():
                tools.append({
                    "name": name,
                    "description": f"KitchenOwl tool: {name}",
                    "inputSchema": schema,
                })
            return _jsonrpc_ok(id_value, {"tools": tools})

        if method == "tools/call":
            name = params.get("name")
            args = params.get("arguments") or {}
            if name not in TOOLS:
                return _jsonrpc_err(id_value, -32601, f"Unknown tool: {name}")
            _, handler = TOOLS[name]
            result = handler(args)
            db.session.commit()
            return _jsonrpc_ok(id_value, _as_tool_result(result))

        return _jsonrpc_err(id_value, -32601, f"Method not found: {method}")
    except Exception as e:
        db.session.rollback()
        return _jsonrpc_err(id_value, -32000, str(e))
