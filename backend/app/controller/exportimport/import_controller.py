from .schemas import ImportSchema
from app.helpers import validate_args
from flask import jsonify
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app import app
from app.config import APP_DIR, SUPPORTED_LANGUAGES
from app.models import Item, Recipe, RecipeItems
import json
from os.path import exists


@app.route('/import', methods=['POST'])
@jwt_required()
@validate_args(ImportSchema)
def importData(args):
    _import(args)
    return jsonify({'msg': 'DONE'})


@app.route('/import/<lang>', methods=['GET'])
@jwt_required()
def importLang(lang):
    file_path = f'{APP_DIR}/../templates/{lang}.json'
    if lang not in SUPPORTED_LANGUAGES or not exists(file_path):
        raise NotFoundRequest('Language code not supported')
    with open(file_path, 'r') as f:
        data = json.load(f)
    _import(data)
    return jsonify({'msg': 'DONE'})


@app.route('/supported-languages', methods=['GET'])
@jwt_required()
def getSupportedLanguages():
    return jsonify(SUPPORTED_LANGUAGES)


def _import(args):
    if "items" in args:
        for importItem in args['items']:
            if not Item.find_by_name(importItem['name']):
                Item.create_by_name(importItem['name'])
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
                        item = Item.create_by_name(recipeItem['name'])
                    con = RecipeItems(
                        description=recipeItem['description'],
                        optional=recipeItem['optional']
                    )
                    con.item = item
                    con.recipe = recipe
                    con.save()
