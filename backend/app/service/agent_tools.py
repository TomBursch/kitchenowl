"""Shared tool implementations for KitchenOwl agents.

These functions are exposed both via the MCP controller (JSON-RPC) and via
the built-in LLM agent (OpenAI/litellm function calling). They run with the
permissions of ``current_user`` and rely on the same authorization checks
used by the rest of the API, so it is safe to invoke them from either entry
point.

Each tool takes a single ``args`` dict and returns a JSON-serialisable value.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Callable

from flask_jwt_extended import current_user

from app import db
from app.errors import NotFoundRequest
from app.models import (
    AgentRecipeCard,
    AgentChat,
    CARD_SOURCE_EXISTING,
    History,
    Household,
    HouseholdMember,
    Item,
    LLMConfig,
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
from app.service.recipe_scraping import scrape
from app.service.web_search import search_recipes_web


def _require_household_access(household_id: int) -> None:
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if not member:
        raise NotFoundRequest()


def _tool_list_households(_args: dict[str, Any]) -> Any:
    members = HouseholdMember.find_by_user(current_user.id)
    return {"items": [m.household.obj_to_dict() for m in members]}


def _tool_list_shoppinglists(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    return {
        "items": [
            e.obj_to_dict() for e in Shoppinglist.all_from_household(household_id)
        ]
    }


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
    recipes = (
        Recipe.query.filter(Recipe.household_id == household_id)
        .order_by(Recipe.name)
        .all()
    )
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
    return {"items": [r.obj_to_full_dict() for r in recipes]}


def _tool_create_recipe(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)

    recipe = Recipe()
    recipe.name = str(args["name"]).strip()[:128]
    recipe.description = str(args.get("description", ""))
    recipe.household_id = household_id

    if "time" in args and args["time"] is not None:
        recipe.time = int(args["time"])
    if "cook_time" in args and args["cook_time"] is not None:
        recipe.cook_time = int(args["cook_time"])
    if "prep_time" in args and args["prep_time"] is not None:
        recipe.prep_time = int(args["prep_time"])
    if "yields" in args and args["yields"] is not None:
        recipe.yields = int(args["yields"])
    if "source" in args and args["source"] is not None:
        recipe.source = str(args["source"])
    if "visibility" in args and args["visibility"] is not None:
        recipe.visibility = RecipeVisibility(int(args["visibility"]))

    recipe.save()

    for recipe_item in args.get("items") or []:
        if isinstance(recipe_item, str):
            item_name = recipe_item
            item_description = ""
            item_optional = False
        else:
            item_name = str(recipe_item.get("name", "")).strip()
            item_description = str(recipe_item.get("description", ""))
            item_optional = bool(recipe_item.get("optional", False))

        if not item_name:
            continue

        item = Item.find_by_name(household_id, item_name)
        if not item:
            item = Item.create_by_name(household_id, item_name)

        con = RecipeItems(description=item_description, optional=item_optional)
        con.item = item
        con.recipe = recipe
        con.save()

    for tag_name in args.get("tags") or []:
        name = str(tag_name).strip()
        if not name:
            continue
        tag = Tag.find_by_name(household_id, name)
        if not tag:
            tag = Tag.create_by_name(household_id, name)
        con = RecipeTags()
        con.tag = tag
        con.recipe = recipe
        con.save()

    return recipe.obj_to_full_dict()


def _tool_get_recipe(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()
    return recipe.obj_to_full_dict()


def _tool_attach_recipe_card(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    chat_id = int(args["chat_id"])
    recipe_id = int(args["recipe_id"])
    group_label_raw = args.get("group_label")
    _require_household_access(household_id)

    chat = AgentChat.find_by_id(chat_id)
    if not chat or chat.household_id != household_id:
        raise NotFoundRequest()

    recipe = Recipe.find_by_id(recipe_id)
    if not recipe or recipe.household_id != household_id:
        raise NotFoundRequest()

    group_label: str | None = None
    if group_label_raw is not None:
        text = str(group_label_raw).strip()
        group_label = text[:64] if text else None

    existing = AgentRecipeCard.query.filter(
        AgentRecipeCard.chat_id == chat.id,
        AgentRecipeCard.recipe_id == recipe.id,
        AgentRecipeCard.closed_at.is_(None),
    ).first()
    if existing:
        if group_label_raw is not None:
            existing.group_label = group_label
            existing.save()
        return existing.obj_to_dict()

    max_pos = (
        db.session.query(db.func.coalesce(db.func.max(AgentRecipeCard.position), -1))
        .filter(AgentRecipeCard.chat_id == chat.id)
        .scalar()
    )
    next_pos = int(max_pos or 0) + 1

    card = AgentRecipeCard(
        chat_id=chat.id,
        recipe_id=recipe.id,
        source=CARD_SOURCE_EXISTING,
        title=(recipe.name or "Rezept")[:255],
        description=(recipe.description or "")[:600],
        position=next_pos,
        group_label=group_label,
    )
    card.save()
    return card.obj_to_dict()


def _tool_delete_recipe(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()
    name = recipe.name
    recipe.delete()
    return {"deleted": True, "id": recipe_id, "name": name}


def _tool_list_items(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    search = str(args.get("search", "")).strip()

    q = Item.query.filter(Item.household_id == household_id)
    if search:
        q = q.filter(Item.name.ilike(f"%{search}%"))
    items = q.order_by(Item.name).limit(100).all()
    return {"items": [i.obj_to_dict() for i in items]}


def _tool_list_tags(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    tags = Tag.query.filter(Tag.household_id == household_id).order_by(Tag.name).all()
    return {"items": [t.obj_to_full_dict() for t in tags]}


def _tool_create_tag(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()
    if not name:
        return {"created": False, "reason": "empty_name"}

    tag = Tag.find_by_name(household_id, name)
    if not tag:
        tag = Tag.create_by_name(household_id, name)
    return tag.obj_to_full_dict()


def _tool_create_shoppinglist(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    name = str(args["name"]).strip()[:128]
    if not name:
        return {"created": False, "reason": "empty_name"}

    shoppinglist = Shoppinglist(name=name, household_id=household_id)
    shoppinglist.save()
    return shoppinglist.obj_to_dict()


def _tool_delete_shoppinglist(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    if shoppinglist.isDefault():
        return {"deleted": False, "reason": "default_list"}

    name = shoppinglist.name
    shoppinglist.delete()
    return {"deleted": True, "id": list_id, "name": name}


def _tool_remove_item_from_list(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()

    item_id = args.get("item_id")
    item_name = str(args.get("name", "")).strip()

    con = None
    if item_id is not None:
        con = ShoppinglistItems.find_by_ids(list_id, int(item_id))
    elif item_name:
        item = Item.find_by_name(shoppinglist.household_id, item_name)
        if item:
            con = ShoppinglistItems.find_by_ids(list_id, item.id)

    if not con:
        return {"removed": False, "reason": "not_found"}

    removed_item = con.item.obj_to_dict()
    con.delete()
    return {"removed": True, "list_id": list_id, "item": removed_item}


def _tool_add_recipe_item(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    item_name = str(args["name"]).strip()
    if not item_name:
        return {"added": False, "reason": "empty_name"}

    item = Item.find_by_name(recipe.household_id, item_name)
    if not item:
        item = Item.create_by_name(recipe.household_id, item_name)

    con = RecipeItems.find_by_ids(recipe.id, item.id)
    if not con:
        con = RecipeItems(
            description=str(args.get("description", "")),
            optional=bool(args.get("optional", False)),
        )
    else:
        if "description" in args:
            con.description = str(args.get("description", ""))
        if "optional" in args:
            con.optional = bool(args.get("optional", False))

    con.item = item
    con.recipe = recipe
    con.save()
    return recipe.obj_to_full_dict()


def _tool_remove_recipe_item(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    item_id = int(args["item_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    con = RecipeItems.find_by_ids(recipe_id, item_id)
    if not con:
        return {"removed": False, "reason": "not_found"}
    con.delete()
    return recipe.obj_to_full_dict()


def _tool_add_recipe_tag(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    tag_name = str(args["name"]).strip()
    if not tag_name:
        return {"added": False, "reason": "empty_name"}

    tag = Tag.find_by_name(recipe.household_id, tag_name)
    if not tag:
        tag = Tag.create_by_name(recipe.household_id, tag_name)

    con = RecipeTags.find_by_ids(recipe.id, tag.id)
    if not con:
        con = RecipeTags()
        con.tag = tag
        con.recipe = recipe
        con.save()

    return recipe.obj_to_full_dict()


def _tool_remove_recipe_tag(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    tag_id = args.get("tag_id")
    tag_name = str(args.get("name", "")).strip()

    con = None
    if tag_id is not None:
        con = RecipeTags.find_by_ids(recipe.id, int(tag_id))
    elif tag_name:
        tag = Tag.find_by_name(recipe.household_id, tag_name)
        if tag:
            con = RecipeTags.find_by_ids(recipe.id, tag.id)

    if not con:
        return {"removed": False, "reason": "not_found"}

    con.delete()
    return recipe.obj_to_full_dict()


def _tool_update_recipe(args: dict[str, Any]) -> Any:
    recipe_id = int(args["recipe_id"])
    recipe = Recipe.find_by_id(recipe_id)
    if not recipe:
        raise NotFoundRequest()
    recipe.checkAuthorized()

    if "name" in args:
        recipe.name = str(args["name"]).strip()[:128]
    if "description" in args:
        recipe.description = str(args.get("description", ""))
    if "time" in args:
        recipe.time = int(args["time"]) if args["time"] is not None else None
    if "cook_time" in args:
        recipe.cook_time = (
            int(args["cook_time"]) if args["cook_time"] is not None else None
        )
    if "prep_time" in args:
        recipe.prep_time = (
            int(args["prep_time"]) if args["prep_time"] is not None else None
        )
    if "yields" in args:
        recipe.yields = int(args["yields"]) if args["yields"] is not None else None
    if "source" in args:
        recipe.source = str(args["source"]) if args["source"] is not None else None
    if "visibility" in args and args["visibility"] is not None:
        recipe.visibility = RecipeVisibility(int(args["visibility"]))

    recipe.save()
    return recipe.obj_to_full_dict()


def _tool_list_expenses(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    search = str(args.get("search", "")).strip()
    _require_household_access(household_id)

    q = Expense.query.filter(Expense.household_id == household_id)
    if search:
        q = q.filter(Expense.name.ilike(f"%{search}%"))
    expenses = q.order_by(Expense.date.desc()).limit(50).all()
    return {"items": [e.obj_to_full_dict() for e in expenses]}


def _tool_create_expense(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)

    expense = Expense()
    expense.household_id = household_id
    expense.name = str(args["name"]).strip()[:128]
    expense.amount = float(args["amount"])
    expense.description = str(args.get("description", ""))
    expense.paid_by_id = current_user.id

    date_raw = args.get("date")
    if date_raw:
        expense.date = datetime.fromisoformat(str(date_raw).replace("Z", "+00:00"))

    expense.save()
    return expense.obj_to_full_dict()


def _tool_delete_expense(args: dict[str, Any]) -> Any:
    expense_id = int(args["expense_id"])
    expense = Expense.find_by_id(expense_id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()
    name = expense.name
    expense.delete()
    return {"deleted": True, "id": expense_id, "name": name}


def _tool_add_planner_entry(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    recipe_id = int(args["recipe_id"])
    _require_household_access(household_id)

    recipe = Recipe.find_by_id(recipe_id)
    if not recipe or recipe.household_id != household_id:
        raise NotFoundRequest()

    cooking_date = datetime.fromisoformat(
        str(args["cooking_date"]).replace("Z", "+00:00")
    )

    existing = Planner.query.filter(
        Planner.household_id == household_id,
        Planner.recipe_id == recipe_id,
        Planner.cooking_date == cooking_date,
    ).first()
    if existing:
        return existing.obj_to_full_dict()

    plan = Planner(
        household_id=household_id,
        recipe_id=recipe_id,
        cooking_date=cooking_date,
        yields=int(args.get("yields", 1)),
    )
    plan.save()
    return plan.obj_to_full_dict()


def _tool_remove_planner_entry(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    recipe_id = int(args["recipe_id"])
    cooking_date = datetime.fromisoformat(
        str(args["cooking_date"]).replace("Z", "+00:00")
    )
    _require_household_access(household_id)

    plan = Planner.query.filter(
        Planner.household_id == household_id,
        Planner.recipe_id == recipe_id,
        Planner.cooking_date == cooking_date,
    ).first()
    if not plan:
        return {"removed": False, "reason": "not_found"}

    plan.delete()
    return {
        "removed": True,
        "household_id": household_id,
        "recipe_id": recipe_id,
        "cooking_date": cooking_date,
    }


def _tool_list_planner(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    plans = Planner.all_from_household(household_id)
    return {"items": [p.obj_to_full_dict() for p in plans]}


def _tool_scrape_recipe(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    url = str(args["url"]).strip()
    _require_household_access(household_id)

    household = Household.find_by_id(household_id)
    if not household:
        raise NotFoundRequest()

    res = scrape(url, household)
    if not res:
        raise ValueError("Unsupported website")
    return res


def _tool_web_search_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    query = str(args["query"]).strip()
    if not query:
        return {"items": []}
    _require_household_access(household_id)

    max_results = int(args.get("max_results", 5) or 5)
    max_results = max(1, min(10, max_results))
    cfg = LLMConfig.find_by_household(household_id)
    brave_api_key = cfg.get_brave_search_api_key() if cfg else None
    results = search_recipes_web(
        query,
        max_results=max_results,
        brave_api_key=brave_api_key,
    )
    return {"items": results}


# Mapping of tool name -> (input JSON-Schema, handler)
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
    "create_recipe": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
                "description": {"type": "string"},
                "time": {"type": "integer"},
                "cook_time": {"type": "integer"},
                "prep_time": {"type": "integer"},
                "yields": {"type": "integer"},
                "source": {"type": "string"},
                "visibility": {"type": "integer", "enum": [0, 1, 2]},
                "items": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string"},
                            "description": {"type": "string"},
                            "optional": {"type": "boolean"},
                        },
                        "required": ["name"],
                    },
                },
                "tags": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_recipe,
    ),
    "get_recipe": (
        {
            "type": "object",
            "properties": {"recipe_id": {"type": "integer"}},
            "required": ["recipe_id"],
        },
        _tool_get_recipe,
    ),
    "attach_recipe_card": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "chat_id": {"type": "integer"},
                "recipe_id": {"type": "integer"},
                "group_label": {"type": "string"},
            },
            "required": ["household_id", "chat_id", "recipe_id"],
        },
        _tool_attach_recipe_card,
    ),
    "delete_recipe": (
        {
            "type": "object",
            "properties": {"recipe_id": {"type": "integer"}},
            "required": ["recipe_id"],
        },
        _tool_delete_recipe,
    ),
    "list_items": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "search": {"type": "string"},
            },
            "required": ["household_id"],
        },
        _tool_list_items,
    ),
    "list_tags": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_tags,
    ),
    "create_tag": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_tag,
    ),
    "create_shoppinglist": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["household_id", "name"],
        },
        _tool_create_shoppinglist,
    ),
    "delete_shoppinglist": (
        {
            "type": "object",
            "properties": {"list_id": {"type": "integer"}},
            "required": ["list_id"],
        },
        _tool_delete_shoppinglist,
    ),
    "remove_item_from_list": (
        {
            "type": "object",
            "properties": {
                "list_id": {"type": "integer"},
                "item_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["list_id"],
        },
        _tool_remove_item_from_list,
    ),
    "add_recipe_item": (
        {
            "type": "object",
            "properties": {
                "recipe_id": {"type": "integer"},
                "name": {"type": "string"},
                "description": {"type": "string"},
                "optional": {"type": "boolean"},
            },
            "required": ["recipe_id", "name"],
        },
        _tool_add_recipe_item,
    ),
    "remove_recipe_item": (
        {
            "type": "object",
            "properties": {
                "recipe_id": {"type": "integer"},
                "item_id": {"type": "integer"},
            },
            "required": ["recipe_id", "item_id"],
        },
        _tool_remove_recipe_item,
    ),
    "add_recipe_tag": (
        {
            "type": "object",
            "properties": {
                "recipe_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["recipe_id", "name"],
        },
        _tool_add_recipe_tag,
    ),
    "remove_recipe_tag": (
        {
            "type": "object",
            "properties": {
                "recipe_id": {"type": "integer"},
                "tag_id": {"type": "integer"},
                "name": {"type": "string"},
            },
            "required": ["recipe_id"],
        },
        _tool_remove_recipe_tag,
    ),
    "update_recipe": (
        {
            "type": "object",
            "properties": {
                "recipe_id": {"type": "integer"},
                "name": {"type": "string"},
                "description": {"type": "string"},
                "time": {"type": "integer"},
                "cook_time": {"type": "integer"},
                "prep_time": {"type": "integer"},
                "yields": {"type": "integer"},
                "source": {"type": "string"},
                "visibility": {"type": "integer", "enum": [0, 1, 2]},
            },
            "required": ["recipe_id"],
        },
        _tool_update_recipe,
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
    "create_expense": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "name": {"type": "string"},
                "amount": {"type": "number"},
                "description": {"type": "string"},
                "date": {"type": "string"},
            },
            "required": ["household_id", "name", "amount"],
        },
        _tool_create_expense,
    ),
    "delete_expense": (
        {
            "type": "object",
            "properties": {"expense_id": {"type": "integer"}},
            "required": ["expense_id"],
        },
        _tool_delete_expense,
    ),
    "list_planner": (
        {
            "type": "object",
            "properties": {"household_id": {"type": "integer"}},
            "required": ["household_id"],
        },
        _tool_list_planner,
    ),
    "add_planner_entry": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "recipe_id": {"type": "integer"},
                "cooking_date": {"type": "string"},
                "yields": {"type": "integer"},
            },
            "required": ["household_id", "recipe_id", "cooking_date"],
        },
        _tool_add_planner_entry,
    ),
    "remove_planner_entry": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "recipe_id": {"type": "integer"},
                "cooking_date": {"type": "string"},
            },
            "required": ["household_id", "recipe_id", "cooking_date"],
        },
        _tool_remove_planner_entry,
    ),
    "scrape_recipe": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "url": {"type": "string"},
            },
            "required": ["household_id", "url"],
        },
        _tool_scrape_recipe,
    ),
    "web_search_recipes": (
        {
            "type": "object",
            "properties": {
                "household_id": {"type": "integer"},
                "query": {
                    "type": "string",
                    "description": "Free-form search query, e.g. 'vegan tomato pasta recipe'.",
                },
                "max_results": {
                    "type": "integer",
                    "description": "Number of results to return (1-10, default 5).",
                },
            },
            "required": ["household_id", "query"],
        },
        _tool_web_search_recipes,
    ),
}


# Tools the LLM recipe agent is allowed to call. We deliberately exclude
# destructive or irrelevant operations (delete recipe/expense/shoppinglist,
# planner mutations, expense management) so the agent stays focused on its
# main purpose: proposing and creating recipes. ``list_households`` is also
# excluded: the agent is bound to a single chat/household and must not be
# able to discover or operate on any other household the caller is part of.
AGENT_TOOL_ALLOWLIST: tuple[str, ...] = (
    "list_recipes",
    "search_recipes",
    "get_recipe",
    "attach_recipe_card",
    "create_recipe",
    "update_recipe",
    "add_recipe_item",
    "remove_recipe_item",
    "add_recipe_tag",
    "remove_recipe_tag",
    "list_items",
    "list_tags",
    "create_tag",
    "scrape_recipe",
    "web_search_recipes",
)


def get_agent_tools() -> dict[
    str, tuple[dict[str, Any], Callable[[dict[str, Any]], Any]]
]:
    """Return the subset of TOOLS the recipe agent may invoke."""
    return {name: TOOLS[name] for name in AGENT_TOOL_ALLOWLIST if name in TOOLS}
