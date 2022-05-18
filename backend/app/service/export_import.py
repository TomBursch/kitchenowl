from app.config import APP_DIR, SUPPORTED_LANGUAGES
from os.path import exists
import json

from app.errors import NotFoundRequest
from app.models import Item, Recipe, RecipeItems, Tag, RecipeTags, Category


def importFromLanguage(lang):
    file_path = f'{APP_DIR}/../templates/{lang}.json'
    if lang not in SUPPORTED_LANGUAGES or not exists(file_path):
        raise NotFoundRequest('Language code not supported')
    with open(file_path, 'r') as f:
        data = json.load(f)
    importFromDict(data, True)


def importFromDict(args, default=False):  # noqa
    if "items" in args:
        for importItem in args['items']:
            if not Item.find_by_name(importItem['name']):
                item = Item()
                item.name = importItem['name']
                item.default = default
                if "category" in importItem:
                    category = Category.find_by_name(importItem['category'])
                    if not category:
                        category = Category.create_by_name(
                            importItem['category'], default)
                    item.category = category
                item.save()
    if "recipes" in args:
        for importRecipe in args['recipes']:
            recipeNameCount = 0
            if Recipe.find_by_name(importRecipe['name']):
                recipeNameCount = 1 + \
                    Recipe.query.filter(Recipe.name.ilike(
                        importRecipe['name'] + " (_%)")).count()
            recipe = Recipe()
            recipe.name = importRecipe['name'] + \
                (f" ({recipeNameCount + 1})" if recipeNameCount > 0 else "")
            recipe.description = importRecipe['description']
            recipe.save()
            if 'items' in importRecipe:
                for recipeItem in importRecipe['items']:
                    item = Item.find_by_name(recipeItem['name'])
                    if not item:
                        item = Item.create_by_name(recipeItem['name'], default)
                    con = RecipeItems(
                        description=recipeItem['description'],
                        optional=recipeItem['optional']
                    )
                    con.item = item
                    con.recipe = recipe
                    con.save()
            if 'tags' in args:
                for tagName in args['tags']:
                    tag = Tag.find_by_name(tagName)
                    if not tag:
                        tag = Tag.create_by_name(recipeItem['name'])
                    con = RecipeTags()
                    con.tag = tag
                    con.recipe = recipe
                    con.save()
