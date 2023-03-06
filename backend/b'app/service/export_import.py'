import time
from app.config import app, APP_DIR, SUPPORTED_LANGUAGES, db
from os.path import exists
import json

from app.errors import NotFoundRequest
from app.models import Item, Recipe, RecipeItems, Tag, RecipeTags, Category


def importFromLanguage(lang, bulkSave=False):
    file_path = f'{APP_DIR}/../templates/l10n/{lang}.json'
    if lang not in SUPPORTED_LANGUAGES or not exists(file_path):
        raise NotFoundRequest('Language code not supported')
    with open(file_path, 'r') as f:
        data = json.load(f)
    with open(f'{APP_DIR}/../templates/attributes.json', 'r') as f:
        attributes = json.load(f)

    t0 = time.time()
    models: list[Item] = []
    for key, name in data["items"].items():
        item = Item.find_by_name(name)
        if not item:
            if bulkSave and any(i.name == name for i in models): # slow but needed to filter out duplicate names
                continue
            item = Item()
            item.name = name.strip()
            item.default = True

        if key in attributes["items"] and "icon" in attributes["items"][key]:
            item.icon = attributes["items"][key]["icon"]

        # Category not already set for existing item and category set for template and category translation exist for language
        if not item.category_id and key in attributes["items"] and "category" in attributes["items"][key] and attributes["items"][key]["category"] in data["categories"]:
            category_name = data["categories"][attributes["items"]
                                               [key]["category"]]
            category = Category.find_by_name(category_name)
            if not category:
                category = Category.create_by_name(category_name, True)
            item.category = category
        if not bulkSave:
            item.save()
        else:
            models.append(item)

    if bulkSave:
        try:
            db.session.add_all(models)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e
    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")


def importFromDict(args, bulkSave=False, override=False):  # noqa
    t0 = time.time()
    models = []
    if "items" in args:
        for importItem in args['items']:
            item = Item.find_by_name(importItem['name'])
            if not item:
                if bulkSave and any(i.name == importItem['name'] for i in models): # slow but needed to filter out duplicate names
                    continue
                item = Item()
                item.name = importItem['name']
            if "category" in importItem and not item.category_id:
                category = Category.find_by_name(importItem['category'])
                if not category:
                    category = Category.create_by_name(
                        importItem['category'])
                item.category = category
            if not bulkSave:
                item.save()
            else:
                models.append(item)
    if "recipes" in args:
        for importRecipe in args['recipes']:
            recipeNameCount = 0
            recipe = Recipe.find_by_name(importRecipe['name'])
            if recipe and not override:
                recipeNameCount = 1 + \
                    Recipe.query.filter(Recipe.name.ilike(
                        importRecipe['name'] + " (_%)")).count()
            if not recipe:
                recipe = Recipe()
            recipe.name = importRecipe['name'] + \
                (f" ({recipeNameCount + 1})" if recipeNameCount > 0 else "")
            recipe.description = importRecipe['description']
            if 'time' in importRecipe:
                recipe.time = importRecipe['time']
            if 'cook_time' in importRecipe:
                recipe.cook_time = importRecipe['cook_time']
            if 'prep_time' in importRecipe:
                recipe.prep_time = importRecipe['prep_time']
            if 'yields' in importRecipe:
                recipe.yields = importRecipe['yields']
            if 'source' in importRecipe:
                recipe.source = importRecipe['source']

            if not bulkSave:
                recipe.save()
            else:
                models.append(recipe)

            if 'items' in importRecipe:
                for recipeItem in importRecipe['items']:
                    item = Item.find_by_name(recipeItem['name'])
                    if not item:
                        item = Item.create_by_name(recipeItem['name'])
                    con = RecipeItems(
                        description=recipeItem['description'],
                        optional=recipeItem['optional']
                    )
                    con.item = item
                    con.recipe = recipe
                    if not bulkSave:
                        con.save()
                    else:
                        models.append(con)
            if 'tags' in args:
                for tagName in args['tags']:
                    tag = Tag.find_by_name(tagName)
                    if not tag:
                        tag = Tag.create_by_name(tagName)
                    con = RecipeTags()
                    con.tag = tag
                    con.recipe = recipe
                    if not bulkSave:
                        con.save()
                    else:
                        models.append(con)

    if bulkSave:
        try:
            db.session.add_all(models)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e
    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")
