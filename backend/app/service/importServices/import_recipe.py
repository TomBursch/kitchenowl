import re

from typing import Any
from app.models import Recipe, RecipeTags, RecipeItems, Item, Tag
from app.service.file_has_access_or_download import file_has_access_or_download


def _to_reference(value: str) -> str:
    return (
        value.lower()
        .replace(" ", "_")
        .replace("\n", "")
        .replace("\r", "")
        .replace("\t", "")
    )


def _apply_ingredient_refs(description: str, item_names: list[str]) -> str:
    if not description or not item_names:
        return description
    names = [n for n in item_names if n]
    if not names:
        return description
    pattern = "|".join(
        [re.escape(name) for name in sorted(names, key=len, reverse=True)]
    )
    if not pattern:
        return description

    def _replace(match: re.Match[str]) -> str:
        name = match.group(1)
        if not name:
            return match.group(0)
        return "@" + re.sub(
            r"\n|\.|\(|\)|\\|/|\?|\*|\+|,|!|%|\$|#|@|\^|;|:|\"|=|~|\{",
            "",
            _to_reference(name),
        )

    return re.sub(
        rf"(?<!@)\b({pattern})\b",
        _replace,
        description,
        flags=re.IGNORECASE,
    )


def _normalize_photo_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(entry).strip() for entry in value if str(entry).strip()]


def importRecipe(
    household_id: int,
    args: dict,
    overwrite: bool = False,
    user=None,
):
    recipeNameCount = 0
    recipe = Recipe.find_by_name(household_id, args["name"])
    if recipe and not overwrite:
        recipeNameCount = (
            1
            + Recipe.query.filter(
                Recipe.household_id == household_id,
                Recipe.name.ilike(args["name"] + " (_%)"),
            ).count()
        )
        recipe = None
    if not recipe:
        recipe = Recipe()
        recipe.household_id = household_id
    recipe.name = args["name"] + (
        f" ({recipeNameCount + 1})" if recipeNameCount > 0 else ""
    )
    description = args["description"]
    if "items" in args:
        description = _apply_ingredient_refs(
            description,
            [str(e.get("name", "")) for e in args["items"] if isinstance(e, dict)],
        )
    recipe.description = description
    if "time" in args:
        recipe.time = args["time"]
    if "cook_time" in args:
        recipe.cook_time = args["cook_time"]
    if "prep_time" in args:
        recipe.prep_time = args["prep_time"]
    if "yields" in args:
        recipe.yields = args["yields"]
    if "source" in args:
        recipe.source = args["source"]
    if "photo" in args:
        recipe.photo = file_has_access_or_download(args["photo"], user=user)
    extra_photos = _normalize_photo_list(args.get("photos"))
    if extra_photos:
        resolved_photos = [
            file_has_access_or_download(photo, user=user) for photo in extra_photos
        ]
        recipe.photos = [photo for photo in resolved_photos if photo]
    elif "photos" in args:
        recipe.photos = []

    recipe.save()

    if "items" in args:
        seen_item_ids: set[int] = set()
        for recipeItem in args["items"]:
            item_name = str(recipeItem["name"]).strip()
            if not item_name:
                continue
            item = Item.find_by_name(household_id, item_name)
            if not item:
                item = Item.create_by_name(household_id, item_name)
            if item.id in seen_item_ids:
                continue
            seen_item_ids.add(item.id)

            con = RecipeItems.find_by_ids(recipe.id, item.id)
            if not con:
                con = RecipeItems(
                    description=recipeItem["description"],
                    optional=recipeItem["optional"],
                )
            else:
                if "description" in recipeItem:
                    con.description = recipeItem["description"]
                if "optional" in recipeItem:
                    con.optional = recipeItem["optional"]
            con.item = item
            con.recipe = recipe
            con.save()
    if "tags" in args:
        seen_tag_ids: set[int] = set()
        for tagName in args["tags"]:
            tag = Tag.find_by_name(household_id, tagName)
            if not tag:
                tag = Tag.create_by_name(household_id, tagName)
            if tag.id in seen_tag_ids:
                continue
            seen_tag_ids.add(tag.id)

            con = RecipeTags.find_by_ids(recipe.id, tag.id)
            if not con:
                con = RecipeTags()
                con.tag = tag
                con.recipe = recipe
                con.save()
