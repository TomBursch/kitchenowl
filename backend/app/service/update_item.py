from typing import Any

from app.errors import InvalidUsage
from app.models import Category, Item


def update_item(item: Item, args: dict[str, Any]) -> Item:
    """Apply an UpdateItem payload to an item the caller is authorized for.

    Shared by POST /api/item/<id> and the MCP update_item tool. A falsy
    "category" removes the category; a name already used by another item of
    the household is ignored.
    """
    if "category" in args:
        if not args["category"]:
            item.category = None
        elif "id" in args["category"]:
            category = Category.find_by_id(args["category"]["id"])
            if not category or category.household_id != item.household_id:
                raise InvalidUsage("Category not found in the item's household")
            item.category = category
        else:
            raise InvalidUsage()
    if "icon" in args:
        item.icon = args["icon"]
    if "name" in args and args["name"] != item.name:
        newName: str = args["name"].strip()[:128]
        # The lookup ignores case, so the item itself matches a case-only rename
        existing = Item.find_by_name(item.household_id, newName)
        if not existing or existing.id == item.id:
            item.name = newName
    item.save()

    if "merge_item_id" in args and args["merge_item_id"] != item.id:
        mergeItem = Item.find_by_id(args["merge_item_id"])
        if mergeItem:
            item.merge(mergeItem)

    return item
