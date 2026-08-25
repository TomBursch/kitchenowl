from __future__ import annotations

import json
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from queue import Empty, Queue
from typing import Any, Callable

from flask import Blueprint, Response, current_app, jsonify, request, url_for
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.config import BACKEND_VERSION
from app.errors import (
    ForbiddenRequest,
    InvalidUsage,
    NotFoundRequest,
    UnauthorizedRequest,
)
from app.models import (
    History,
    Household,
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
from app.service.recipe_scraping import scrape

mcp = Blueprint("mcp", __name__)


DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 200


def _as_tool_result(payload: Any):
    text = json.dumps(payload, ensure_ascii=False, default=str)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": payload,
    }


def _as_tool_error(message: str):
    return {"content": [{"type": "text", "text": message}], "isError": True}


def _tool_error_message(error: Exception) -> str:
    if isinstance(error, (NotFoundRequest, ForbiddenRequest, UnauthorizedRequest, InvalidUsage)):
        return error.message
    if isinstance(error, KeyError):
        return f"Missing required argument: {error.args[0]}"
    if isinstance(error, (ValueError, TypeError)):
        return str(error)
    current_app.logger.exception("MCP tool failed")
    return "The tool failed unexpectedly. The error has been logged."


def _page_args(args: dict[str, Any]) -> tuple[int, int]:
    limit = min(max(int(args.get("limit", DEFAULT_PAGE_SIZE)), 1), MAX_PAGE_SIZE)
    return limit, max(int(args.get("offset", 0)), 0)


def _paginate_query(query, args: dict[str, Any], serialize) -> dict[str, Any]:
    limit, offset = _page_args(args)
    total = query.count()
    rows = query.limit(limit).offset(offset).all()
    return {
        "items": [serialize(r) for r in rows],
        "total": total,
        "offset": offset,
        "has_more": offset + len(rows) < total,
    }


def _paginate_list(rows: list, args: dict[str, Any], serialize) -> dict[str, Any]:
    limit, offset = _page_args(args)
    page = rows[offset : offset + limit]
    return {
        "items": [serialize(r) for r in page],
        "total": len(rows),
        "offset": offset,
        "has_more": offset + len(page) < len(rows),
    }


def _recipe_summary(recipe: Recipe) -> dict[str, Any]:
    # Deliberately omits description, items and the nested household that
    # obj_to_full_dict carries; get_recipe returns those on demand.
    return {
        "id": recipe.id,
        "name": recipe.name,
        "time": recipe.time,
        "cook_time": recipe.cook_time,
        "prep_time": recipe.prep_time,
        "yields": recipe.yields,
        "tags": [t.tag.name for t in recipe.tags],
    }


def _require_household_access(household_id: int):
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if not member:
        raise NotFoundRequest()


def _tool_list_households(args: dict[str, Any]) -> Any:
    members = HouseholdMember.find_by_user(current_user.id)
    return _paginate_list(members, args, lambda m: m.household.obj_to_dict())


def _tool_list_shoppinglists(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    lists = Shoppinglist.all_from_household(household_id)
    return _paginate_list(lists, args, lambda e: e.obj_to_dict())


def _tool_list_shoppinglist_items(args: dict[str, Any]) -> Any:
    list_id = int(args["list_id"])
    shoppinglist = Shoppinglist.find_by_id(list_id)
    if not shoppinglist:
        raise NotFoundRequest()
    shoppinglist.checkAuthorized()
    query = ShoppinglistItems.query.filter(
        ShoppinglistItems.shoppinglist_id == list_id
    ).join(ShoppinglistItems.item)
    return _paginate_query(query, args, lambda e: e.obj_to_item_dict())


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
    query = Recipe.query.filter(Recipe.household_id == household_id).order_by(Recipe.name)
    return _paginate_query(query, args, _recipe_summary)


def _tool_search_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    query = str(args["query"]).strip()
    _require_household_access(household_id)
    matches = (
        Recipe.query.filter(Recipe.household_id == household_id)
        .filter(Recipe.name.ilike(f"%{query}%"))
        .order_by(Recipe.name)
    )
    return _paginate_query(matches, args, _recipe_summary)


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

    for recipe_item in (args.get("items") or []):
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

    for tag_name in (args.get("tags") or []):
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
    return _paginate_query(q.order_by(Item.name), args, lambda i: i.obj_to_dict())


def _tool_list_tags(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    query = Tag.query.filter(Tag.household_id == household_id).order_by(Tag.name)
    return _paginate_query(query, args, lambda t: t.obj_to_full_dict())


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
        recipe.cook_time = int(args["cook_time"]) if args["cook_time"] is not None else None
    if "prep_time" in args:
        recipe.prep_time = int(args["prep_time"]) if args["prep_time"] is not None else None
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
    return _paginate_query(
        q.order_by(Expense.date.desc()), args, lambda e: e.obj_to_full_dict()
    )


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

    cooking_date = datetime.fromisoformat(str(args["cooking_date"]).replace("Z", "+00:00"))

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
    cooking_date = datetime.fromisoformat(str(args["cooking_date"]).replace("Z", "+00:00"))
    _require_household_access(household_id)

    plan = Planner.query.filter(
        Planner.household_id == household_id,
        Planner.recipe_id == recipe_id,
        Planner.cooking_date == cooking_date,
    ).first()
    if not plan:
        return {"removed": False, "reason": "not_found"}

    plan.delete()
    return {"removed": True, "household_id": household_id, "recipe_id": recipe_id, "cooking_date": cooking_date}


def _tool_list_planner(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    plans = Planner.all_from_household(household_id)
    return _paginate_list(plans, args, lambda p: p.obj_to_full_dict())


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


@dataclass(frozen=True)
class Tool:
    title: str
    description: str
    schema: dict[str, Any]
    handler: Callable[[dict[str, Any]], Any]
    read_only: bool = False
    destructive: bool = False
    idempotent: bool = False
    open_world: bool = False

    def annotations(self) -> dict[str, Any]:
        return {
            "title": self.title,
            "readOnlyHint": self.read_only,
            "destructiveHint": self.destructive,
            "idempotentHint": self.idempotent,
            "openWorldHint": self.open_world,
        }


def _schema(properties: dict[str, Any], required: tuple[str, ...] = ()) -> dict[str, Any]:
    return {"type": "object", "properties": properties, "required": list(required)}


def _paged(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        **properties,
        "limit": {
            "type": "integer",
            "minimum": 1,
            "maximum": MAX_PAGE_SIZE,
            "description": f"Rows to return, {1}-{MAX_PAGE_SIZE}, default {DEFAULT_PAGE_SIZE}.",
        },
        "offset": {
            "type": "integer",
            "minimum": 0,
            "description": "Rows to skip. Use with the has_more flag to page through results.",
        },
    }


P_HOUSEHOLD = {
    "type": "integer",
    "description": "Household id, as returned by list_households.",
}
P_LIST = {
    "type": "integer",
    "description": "Shopping list id, as returned by list_shoppinglists.",
}
P_RECIPE = {"type": "integer", "description": "Recipe id, as returned by list_recipes."}
P_QUANTITY = {
    "type": "string",
    "description": (
        "Free-text quantity shown next to the item, e.g. '2 kg', '500 g', '3 x'. "
        "Leave empty if no quantity is needed."
    ),
}
P_COOKING_DATE = {
    "type": "string",
    "description": "Day the recipe is planned for, as an ISO-8601 date-time.",
}
P_VISIBILITY = {
    "type": "integer",
    "enum": [0, 1, 2],
    "description": "0 private to the household, 1 shared by link, 2 public.",
}

RECIPE_FIELDS = {
    "name": {"type": "string", "description": "Recipe name, truncated to 128 characters."},
    "description": {
        "type": "string",
        "description": "The method, as markdown. This is the body of the recipe.",
    },
    "time": {"type": "integer", "description": "Total time in minutes."},
    "cook_time": {"type": "integer", "description": "Cooking time in minutes."},
    "prep_time": {"type": "integer", "description": "Preparation time in minutes."},
    "yields": {"type": "integer", "description": "Number of servings the recipe makes."},
    "source": {"type": "string", "description": "URL or book the recipe came from."},
    "visibility": P_VISIBILITY,
}


TOOLS: dict[str, Tool] = {
    "list_households": Tool(
        title="List households",
        description=(
            "List the households you are a member of. Almost every other tool needs a "
            "household_id, so call this first and reuse the id."
        ),
        schema=_schema(_paged({})),
        handler=_tool_list_households,
        read_only=True,
        idempotent=True,
    ),
    "list_shoppinglists": Tool(
        title="List shopping lists",
        description=(
            "List the shopping lists belonging to a household. Most households have a "
            "single list named 'Default'."
        ),
        schema=_schema(_paged({"household_id": P_HOUSEHOLD}), ("household_id",)),
        handler=_tool_list_shoppinglists,
        read_only=True,
        idempotent=True,
    ),
    "list_shoppinglist_items": Tool(
        title="List items to buy",
        description=(
            "List what is currently on a shopping list, i.e. what still needs buying. "
            "Each entry carries the item name and a free-text description holding the "
            "quantity. To see the household's full item vocabulary instead, use list_items."
        ),
        schema=_schema(_paged({"list_id": P_LIST}), ("list_id",)),
        handler=_tool_list_shoppinglist_items,
        read_only=True,
        idempotent=True,
    ),
    "add_item_by_name": Tool(
        title="Add item to shopping list",
        description=(
            "Put an item on a shopping list, creating it in the household if it is not "
            "already known. Adding an item that is already on the list changes nothing, "
            "so this is safe to retry."
        ),
        schema=_schema(
            {
                "list_id": P_LIST,
                "name": {
                    "type": "string",
                    "description": "Item name on its own, e.g. 'milk'. Put quantities in description.",
                },
                "description": P_QUANTITY,
            },
            ("list_id", "name"),
        ),
        handler=_tool_add_item_by_name,
        idempotent=True,
    ),
    "remove_item_from_list": Tool(
        title="Remove item from shopping list",
        description=(
            "Take an item off a shopping list, typically once it has been bought. "
            "Identify it by item_id or by name. The item itself is kept in the "
            "household so it can be added again later."
        ),
        schema=_schema(
            {
                "list_id": P_LIST,
                "item_id": {"type": "integer", "description": "Item id. Preferred over name."},
                "name": {"type": "string", "description": "Item name, if the id is unknown."},
            },
            ("list_id",),
        ),
        handler=_tool_remove_item_from_list,
        destructive=True,
        idempotent=True,
    ),
    "create_shoppinglist": Tool(
        title="Create shopping list",
        description="Create an additional shopping list in a household.",
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "name": {"type": "string", "description": "List name, e.g. 'Weekly shop'."},
            },
            ("household_id", "name"),
        ),
        handler=_tool_create_shoppinglist,
    ),
    "delete_shoppinglist": Tool(
        title="Delete shopping list",
        description=(
            "Delete a shopping list and everything on it. The household's default list "
            "cannot be deleted."
        ),
        schema=_schema({"list_id": P_LIST}, ("list_id",)),
        handler=_tool_delete_shoppinglist,
        destructive=True,
    ),
    "list_items": Tool(
        title="List known items",
        description=(
            "List the items a household knows about, whether or not they are on a list "
            "right now. Useful for matching a vague request to an existing item instead "
            "of creating a near-duplicate."
        ),
        schema=_schema(
            _paged(
                {
                    "household_id": P_HOUSEHOLD,
                    "search": {
                        "type": "string",
                        "description": "Case-insensitive substring filter on the item name.",
                    },
                }
            ),
            ("household_id",),
        ),
        handler=_tool_list_items,
        read_only=True,
        idempotent=True,
    ),
    "list_recipes": Tool(
        title="List recipes",
        description=(
            "List a household's recipes as summaries: id, name, times, yields and tags. "
            "Ingredients and method are omitted, so call get_recipe for a specific one."
        ),
        schema=_schema(_paged({"household_id": P_HOUSEHOLD}), ("household_id",)),
        handler=_tool_list_recipes,
        read_only=True,
        idempotent=True,
    ),
    "search_recipes": Tool(
        title="Search recipes",
        description=(
            "Find recipes whose name contains the query, case-insensitive. Returns the "
            "same summaries as list_recipes. Matches names only, not ingredients."
        ),
        schema=_schema(
            _paged(
                {
                    "household_id": P_HOUSEHOLD,
                    "query": {"type": "string", "description": "Substring to look for in recipe names."},
                }
            ),
            ("household_id", "query"),
        ),
        handler=_tool_search_recipes,
        read_only=True,
        idempotent=True,
    ),
    "get_recipe": Tool(
        title="Get recipe",
        description="Get one recipe in full, including its method, ingredients and tags.",
        schema=_schema({"recipe_id": P_RECIPE}, ("recipe_id",)),
        handler=_tool_get_recipe,
        read_only=True,
        idempotent=True,
    ),
    "create_recipe": Tool(
        title="Create recipe",
        description=(
            "Create a recipe in a household. Ingredients may be given as plain names or "
            "as objects carrying a quantity description and an optional flag; any that "
            "are new to the household are created. Tags are created on demand too."
        ),
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                **RECIPE_FIELDS,
                "items": {
                    "type": "array",
                    "description": "Ingredients, as names or {name, description, optional} objects.",
                    "items": {
                        "oneOf": [
                            {"type": "string"},
                            {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string", "description": "Ingredient name."},
                                    "description": P_QUANTITY,
                                    "optional": {
                                        "type": "boolean",
                                        "description": "True if the recipe works without it.",
                                    },
                                },
                                "required": ["name"],
                            },
                        ]
                    },
                },
                "tags": {
                    "type": "array",
                    "description": "Tag names, e.g. 'vegetarian'. Created if they do not exist.",
                    "items": {"type": "string"},
                },
            },
            ("household_id", "name"),
        ),
        handler=_tool_create_recipe,
    ),
    "update_recipe": Tool(
        title="Update recipe",
        description=(
            "Change fields on an existing recipe. Only the fields you pass are touched, "
            "and each one replaces the stored value outright. Ingredients and tags are "
            "managed with the add_recipe_item and add_recipe_tag tools."
        ),
        schema=_schema({"recipe_id": P_RECIPE, **RECIPE_FIELDS}, ("recipe_id",)),
        handler=_tool_update_recipe,
        destructive=True,
        idempotent=True,
    ),
    "delete_recipe": Tool(
        title="Delete recipe",
        description="Permanently delete a recipe and its ingredient and tag links.",
        schema=_schema({"recipe_id": P_RECIPE}, ("recipe_id",)),
        handler=_tool_delete_recipe,
        destructive=True,
    ),
    "add_recipe_item": Tool(
        title="Add ingredient to recipe",
        description=(
            "Add an ingredient to a recipe, creating the item in the household if "
            "needed. Calling it for an ingredient already on the recipe updates that "
            "ingredient's quantity and optional flag instead of duplicating it."
        ),
        schema=_schema(
            {
                "recipe_id": P_RECIPE,
                "name": {"type": "string", "description": "Ingredient name, e.g. 'plain flour'."},
                "description": P_QUANTITY,
                "optional": {"type": "boolean", "description": "True if the recipe works without it."},
            },
            ("recipe_id", "name"),
        ),
        handler=_tool_add_recipe_item,
        idempotent=True,
    ),
    "remove_recipe_item": Tool(
        title="Remove ingredient from recipe",
        description="Remove an ingredient from a recipe. The item itself is kept in the household.",
        schema=_schema(
            {
                "recipe_id": P_RECIPE,
                "item_id": {"type": "integer", "description": "Item id, from the recipe's items."},
            },
            ("recipe_id", "item_id"),
        ),
        handler=_tool_remove_recipe_item,
        destructive=True,
        idempotent=True,
    ),
    "list_tags": Tool(
        title="List tags",
        description="List a household's recipe tags, e.g. 'vegetarian' or 'quick'.",
        schema=_schema(_paged({"household_id": P_HOUSEHOLD}), ("household_id",)),
        handler=_tool_list_tags,
        read_only=True,
        idempotent=True,
    ),
    "create_tag": Tool(
        title="Create tag",
        description=(
            "Create a recipe tag in a household. Returns the existing tag if one with "
            "that name is already there."
        ),
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "name": {"type": "string", "description": "Tag name, e.g. 'vegetarian'."},
            },
            ("household_id", "name"),
        ),
        handler=_tool_create_tag,
        idempotent=True,
    ),
    "add_recipe_tag": Tool(
        title="Tag a recipe",
        description="Attach a tag to a recipe, creating the tag in the household if needed.",
        schema=_schema(
            {
                "recipe_id": P_RECIPE,
                "name": {"type": "string", "description": "Tag name to attach."},
            },
            ("recipe_id", "name"),
        ),
        handler=_tool_add_recipe_tag,
        idempotent=True,
    ),
    "remove_recipe_tag": Tool(
        title="Untag a recipe",
        description=(
            "Detach a tag from a recipe, by tag_id or name. The tag itself stays in the "
            "household."
        ),
        schema=_schema(
            {
                "recipe_id": P_RECIPE,
                "tag_id": {"type": "integer", "description": "Tag id. Preferred over name."},
                "name": {"type": "string", "description": "Tag name, if the id is unknown."},
            },
            ("recipe_id",),
        ),
        handler=_tool_remove_recipe_tag,
        destructive=True,
        idempotent=True,
    ),
    "list_planner": Tool(
        title="List meal plan",
        description="List the recipes planned in a household, with the day each is planned for.",
        schema=_schema(_paged({"household_id": P_HOUSEHOLD}), ("household_id",)),
        handler=_tool_list_planner,
        read_only=True,
        idempotent=True,
    ),
    "add_planner_entry": Tool(
        title="Plan a meal",
        description=(
            "Plan a recipe for a given day. Planning the same recipe on the same day "
            "twice changes nothing. The recipe must belong to the household."
        ),
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "recipe_id": P_RECIPE,
                "cooking_date": P_COOKING_DATE,
                "yields": {"type": "integer", "description": "Servings to cook, default 1."},
            },
            ("household_id", "recipe_id", "cooking_date"),
        ),
        handler=_tool_add_planner_entry,
        idempotent=True,
    ),
    "remove_planner_entry": Tool(
        title="Unplan a meal",
        description="Remove a planned recipe from a given day. The recipe itself is kept.",
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "recipe_id": P_RECIPE,
                "cooking_date": P_COOKING_DATE,
            },
            ("household_id", "recipe_id", "cooking_date"),
        ),
        handler=_tool_remove_planner_entry,
        destructive=True,
        idempotent=True,
    ),
    "list_expenses": Tool(
        title="List expenses",
        description="List a household's expenses, most recent first, with who paid and the split.",
        schema=_schema(
            _paged(
                {
                    "household_id": P_HOUSEHOLD,
                    "search": {
                        "type": "string",
                        "description": "Case-insensitive substring filter on the expense name.",
                    },
                }
            ),
            ("household_id",),
        ),
        handler=_tool_list_expenses,
        read_only=True,
        idempotent=True,
    ),
    "create_expense": Tool(
        title="Record expense",
        description=(
            "Record an expense paid by you, in the household's currency. Defaults to now "
            "unless a date is given."
        ),
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "name": {"type": "string", "description": "What the money was spent on."},
                "amount": {"type": "number", "description": "Amount paid, in the household currency."},
                "description": {"type": "string", "description": "Optional longer note."},
                "date": {"type": "string", "description": "When it was paid, ISO-8601. Defaults to now."},
            },
            ("household_id", "name", "amount"),
        ),
        handler=_tool_create_expense,
    ),
    "delete_expense": Tool(
        title="Delete expense",
        description="Permanently delete an expense and rebalance the household accordingly.",
        schema=_schema(
            {"expense_id": {"type": "integer", "description": "Expense id, from list_expenses."}},
            ("expense_id",),
        ),
        handler=_tool_delete_expense,
        destructive=True,
    ),
    "scrape_recipe": Tool(
        title="Import recipe from a URL",
        description=(
            "Fetch a recipe from a web page and return it parsed. Nothing is saved, so "
            "keeping it is a separate step. Fails on sites that publish no "
            "recognisable recipe data."
        ),
        schema=_schema(
            {
                "household_id": P_HOUSEHOLD,
                "url": {"type": "string", "description": "Public URL of the recipe page."},
            },
            ("household_id", "url"),
        ),
        handler=_tool_scrape_recipe,
        read_only=True,
        open_world=True,
    ),
}


SUPPORTED_PROTOCOL_VERSIONS = ("2025-06-18", "2025-03-26", "2024-11-05")
LATEST_PROTOCOL_VERSION = SUPPORTED_PROTOCOL_VERSIONS[0]

SERVER_INSTRUCTIONS = (
    "KitchenOwl manages households, each of which owns shopping lists, items, "
    "recipes, tags, meal plans and expenses. Nearly every tool is scoped to a "
    "household, so call list_households first and reuse the id you get back."
)

SSE_KEEPALIVE_SECONDS = 15


def _dispatch(body: Any) -> Any:
    # Returns the response to send back, or None for notifications, which the
    # protocol requires be left unanswered.
    if isinstance(body, list):
        responses = [r for r in (_dispatch(item) for item in body) if r is not None]
        return responses or None

    if not isinstance(body, dict):
        return {
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32600, "message": "Invalid Request"},
        }

    id_value = body.get("id")
    method = body.get("method")
    params = body.get("params") or {}
    is_notification = "id" not in body

    try:
        if method == "initialize":
            requested = params.get("protocolVersion")
            version = (
                requested
                if requested in SUPPORTED_PROTOCOL_VERSIONS
                else LATEST_PROTOCOL_VERSION
            )
            result = {
                "protocolVersion": version,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {
                    "name": "kitchenowl-mcp",
                    "version": str(BACKEND_VERSION),
                },
                "instructions": SERVER_INSTRUCTIONS,
            }
        elif method is not None and method.startswith("notifications/"):
            return None
        elif method == "ping":
            result = {}
        elif method == "tools/list":
            result = {
                "tools": [
                    {
                        "name": name,
                        "description": tool.description,
                        "inputSchema": tool.schema,
                        "annotations": tool.annotations(),
                    }
                    for name, tool in TOOLS.items()
                ]
            }
        elif method == "tools/call":
            name = params.get("name")
            args = params.get("arguments") or {}
            if name not in TOOLS:
                return None if is_notification else _rpc_error(
                    id_value, -32602, f"Unknown tool: {name}"
                )
            try:
                result = _as_tool_result(TOOLS[name].handler(args))
                db.session.commit()
            except Exception as e:
                # A tool that fails is a result the model can react to, not a
                # protocol fault that should abort the call.
                db.session.rollback()
                result = _as_tool_error(_tool_error_message(e))
        else:
            return None if is_notification else _rpc_error(
                id_value, -32601, f"Method not found: {method}"
            )
    except Exception as e:
        db.session.rollback()
        return None if is_notification else _rpc_error(id_value, -32000, str(e))

    return None if is_notification else {"jsonrpc": "2.0", "id": id_value, "result": result}


def _rpc_error(id_value: Any, code: int, message: str) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": id_value, "error": {"code": code, "message": message}}


# Streamable HTTP. Stateless: no session id is issued, so this transport keeps
# working across multiple uWSGI workers.


@mcp.route("", methods=["POST"])
@jwt_required()
def mcp_post():
    response = _dispatch(request.get_json(silent=True))
    if response is None:
        return "", 202
    return jsonify(response)


@mcp.route("", methods=["GET", "DELETE"])
@jwt_required()
def mcp_stream_unsupported():
    # Nothing to push outside a request and no session to tear down; the spec
    # allows 405 for both.
    return Response(status=405, headers={"Allow": "POST"})


# HTTP+SSE. Both halves of a session must be served by the same process, so this
# registry is deliberately per-worker.


@dataclass
class _SseSession:
    user_id: int
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    outbox: Queue = field(default_factory=Queue)


_sse_sessions: dict[str, _SseSession] = {}


@mcp.route("/sse", methods=["GET"])
@jwt_required()
def mcp_sse():
    session = _SseSession(user_id=current_user.id)
    _sse_sessions[session.id] = session

    # Relative, so it survives a reverse proxy that request.url_root would not.
    endpoint = f"{url_for('mcp.mcp_messages')}?session_id={session.id}"

    def generate():
        try:
            yield f"event: endpoint\ndata: {endpoint}\n\n"
            while True:
                try:
                    message = session.outbox.get(timeout=SSE_KEEPALIVE_SECONDS)
                except Empty:
                    yield ": keep-alive\n\n"
                    continue
                yield "event: message\ndata: {}\n\n".format(
                    json.dumps(message, ensure_ascii=False, default=str)
                )
        finally:
            _sse_sessions.pop(session.id, None)

    return Response(
        generate(),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@mcp.route("/messages", methods=["POST"])
@mcp.route("/messages/<session_id>", methods=["POST"])
@jwt_required()
def mcp_messages(session_id: str | None = None):
    session_id = session_id or request.args.get("session_id")
    session = _sse_sessions.get(session_id) if session_id else None

    if session is None:
        return jsonify({"error": "Unknown or expired session"}), 404
    if session.user_id != current_user.id:
        return jsonify({"error": "Session belongs to a different user"}), 403

    response = _dispatch(request.get_json(silent=True))
    if response is not None:
        session.outbox.put(response)

    # The reply travels over the SSE stream, not this response.
    return "", 202
