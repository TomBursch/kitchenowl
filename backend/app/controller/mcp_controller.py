from __future__ import annotations

import json
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from queue import Empty, Queue
from typing import Any

from flask import Blueprint, Response, jsonify, request, url_for
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.config import BACKEND_VERSION
from app.errors import NotFoundRequest
from app.models import (
    Expense,
    File,
    History,
    Household,
    HouseholdMember,
    Item,
    Planner,
    Recipe,
    RecipeItems,
    RecipeTags,
    Shoppinglist,
    ShoppinglistItems,
    Tag,
)
from app.models.recipe import (
    RecipeVisibility,
    is_within_next_7_days,
    transform_cooking_date_to_day,
)
from app.service.recipe_scraping import scrape

mcp = Blueprint("mcp", __name__)

RECIPE_ADDITIONAL_FIELDS = (
    "description",
    "photo",
    "photo_hash",
    "time",
    "cook_time",
    "prep_time",
    "yields",
    "source",
    "visibility",
    "created_at",
    "updated_at",
    "planned",
    "planned_days",
    "planned_cooking_dates",
    "items",
    "tags",
)
RECIPE_DISCOVERY_ARGUMENTS = {
    "offset": {"type": "integer", "minimum": 0, "default": 0},
    "limit": {
        "type": "integer",
        "minimum": 1,
        "maximum": 100,
        "default": 50,
    },
    "additional_fields": {
        "type": "array",
        "items": {"type": "string", "enum": list(RECIPE_ADDITIONAL_FIELDS)},
        "uniqueItems": True,
        "default": [],
    },
}


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


def _recipe_discovery_page(query, args: dict[str, Any]) -> dict[str, Any]:
    offset = int(args.get("offset", 0))
    limit = int(args.get("limit", 50))
    if offset < 0:
        raise ValueError("offset must be non-negative")
    if limit < 1 or limit > 100:
        raise ValueError("limit must be between 1 and 100")

    raw_additional_fields = args.get("additional_fields", [])
    if not isinstance(raw_additional_fields, list) or not all(
        isinstance(field, str) for field in raw_additional_fields
    ):
        raise ValueError("additional_fields must be an array of strings")
    additional_fields = list(raw_additional_fields)
    if len(additional_fields) != len(set(additional_fields)):
        raise ValueError("additional_fields must not contain duplicates")
    unsupported_fields = sorted(
        set(additional_fields).difference(RECIPE_ADDITIONAL_FIELDS)
    )
    if unsupported_fields:
        raise ValueError(
            "Unsupported additional_fields: " + ", ".join(unsupported_fields)
        )

    scalar_fields = {
        "description": Recipe.description,
        "photo": Recipe.photo,
        "time": Recipe.time,
        "cook_time": Recipe.cook_time,
        "prep_time": Recipe.prep_time,
        "yields": Recipe.yields,
        "source": Recipe.source,
        "visibility": Recipe.visibility,
        "created_at": Recipe.created_at,
        "updated_at": Recipe.updated_at,
    }
    total = query.count()
    columns = [Recipe.id, Recipe.name]
    columns.extend(
        scalar_fields[field]
        for field in additional_fields
        if field in scalar_fields
    )
    rows = (
        query.with_entities(*columns)
        .order_by(Recipe.name, Recipe.id)
        .offset(offset)
        .limit(limit)
        .all()
    )
    items = [dict(row._mapping) for row in rows]
    items_by_id = {item["id"]: item for item in items}

    if "photo_hash" in additional_fields:
        for item in items:
            item["photo_hash"] = None
        if items_by_id:
            photo_hashes = (
                db.session.query(Recipe.id, File.blur_hash)
                .outerjoin(File, Recipe.photo == File.filename)
                .filter(Recipe.id.in_(items_by_id))
                .all()
            )
            for recipe_id, photo_hash in photo_hashes:
                items_by_id[recipe_id]["photo_hash"] = photo_hash

    planning_fields = {
        "planned",
        "planned_days",
        "planned_cooking_dates",
    }
    requested_planning_fields = planning_fields.intersection(additional_fields)
    if requested_planning_fields:
        for item in items:
            if "planned" in requested_planning_fields:
                item["planned"] = False
            if "planned_days" in requested_planning_fields:
                item["planned_days"] = []
            if "planned_cooking_dates" in requested_planning_fields:
                item["planned_cooking_dates"] = []
        if items_by_id:
            plans = (
                db.session.query(Planner.recipe_id, Planner.cooking_date)
                .filter(Planner.recipe_id.in_(items_by_id))
                .order_by(Planner.recipe_id, Planner.cooking_date)
                .all()
            )
            for recipe_id, cooking_date in plans:
                item = items_by_id[recipe_id]
                if "planned" in requested_planning_fields:
                    item["planned"] = True
                if cooking_date <= datetime.min.replace(tzinfo=cooking_date.tzinfo):
                    continue
                if "planned_cooking_dates" in requested_planning_fields:
                    item["planned_cooking_dates"].append(cooking_date)
                if (
                    "planned_days" in requested_planning_fields
                    and is_within_next_7_days(cooking_date)
                ):
                    item["planned_days"].append(
                        transform_cooking_date_to_day(cooking_date)
                    )

    if "items" in additional_fields:
        for item in items:
            item["items"] = []
        if items_by_id:
            recipe_items = (
                db.session.query(
                    RecipeItems.recipe_id,
                    Item.id.label("id"),
                    Item.name.label("name"),
                    RecipeItems.description.label("description"),
                    RecipeItems.optional.label("optional"),
                )
                .join(RecipeItems.item)
                .filter(RecipeItems.recipe_id.in_(items_by_id))
                .order_by(RecipeItems.recipe_id, Item.name, Item.id)
                .all()
            )
            for recipe_item in recipe_items:
                values = dict(recipe_item._mapping)
                recipe_id = values.pop("recipe_id")
                items_by_id[recipe_id]["items"].append(values)

    if "tags" in additional_fields:
        for item in items:
            item["tags"] = []
        if items_by_id:
            recipe_tags = (
                db.session.query(
                    RecipeTags.recipe_id,
                    Tag.id.label("id"),
                    Tag.name.label("name"),
                )
                .join(RecipeTags.tag)
                .filter(RecipeTags.recipe_id.in_(items_by_id))
                .order_by(RecipeTags.recipe_id, Tag.name, Tag.id)
                .all()
            )
            for recipe_tag in recipe_tags:
                values = dict(recipe_tag._mapping)
                recipe_id = values.pop("recipe_id")
                items_by_id[recipe_id]["tags"].append(values)

    returned_until = offset + len(items)
    return {
        "items": items,
        "total": total,
        "next_offset": returned_until if returned_until < total else None,
    }


def _tool_list_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    _require_household_access(household_id)
    query = Recipe.query.filter(Recipe.household_id == household_id)
    return _recipe_discovery_page(query, args)


def _tool_search_recipes(args: dict[str, Any]) -> Any:
    household_id = int(args["household_id"])
    query = str(args["query"]).strip()
    _require_household_access(household_id)
    recipes = (
        Recipe.query.filter(Recipe.household_id == household_id)
        .filter(Recipe.name.ilike(f"%{query}%"))
    )
    return _recipe_discovery_page(recipes, args)


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
            "properties": {
                "household_id": {"type": "integer"},
                **RECIPE_DISCOVERY_ARGUMENTS,
            },
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
                **RECIPE_DISCOVERY_ARGUMENTS,
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
                        "oneOf": [
                            {"type": "string"},
                            {
                                "type": "object",
                                "properties": {
                                    "name": {"type": "string"},
                                    "description": {"type": "string"},
                                    "optional": {"type": "boolean"},
                                },
                                "required": ["name"],
                            },
                        ]
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
}

TOOL_DESCRIPTIONS = {
    "list_recipes": (
        "List household recipes as paginated id and name references. Use "
        "additional_fields for selected bulk data, or get_recipe for one full recipe."
    ),
    "search_recipes": (
        "Search household recipe names and return paginated id and name references. "
        "Use additional_fields for selected bulk data, or get_recipe for one full recipe."
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
                        "description": TOOL_DESCRIPTIONS.get(
                            name, f"KitchenOwl tool: {name}"
                        ),
                        "inputSchema": schema,
                    }
                    for name, (schema, _) in TOOLS.items()
                ]
            }
        elif method == "tools/call":
            name = params.get("name")
            args = params.get("arguments") or {}
            if name not in TOOLS:
                return None if is_notification else _rpc_error(
                    id_value, -32602, f"Unknown tool: {name}"
                )
            _, handler = TOOLS[name]
            result = _as_tool_result(handler(args))
            db.session.commit()
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
