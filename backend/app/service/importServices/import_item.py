from app.models import Household, Item, Category, Store, ItemStores


def importItem(household: Household, args: dict):
    item = Item.find_by_name(household.id, args["name"])
    if not item:
        item = Item()
        item.name = args["name"]
        item.household = household
    if "icon" in args:
        item.icon = args["icon"]
    if "category" in args and not item.category_id:
        category = Category.find_by_name(household.id, args["category"])
        if not category:
            category = Category.create_by_name(household.id, args["category"])
        item.category = category
    if "stores" in args and not item.stores:
        for name in args["stores"]:
            store = Store.find_by_name(household.id, name)
            if not store:
                store = Store.create_by_name(household.id, name)
            item.stores.append(ItemStores(store=store))
    item.save()
