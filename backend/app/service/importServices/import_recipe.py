
from app.models import Recipe, RecipeTags, RecipeItems, Item, Tag
from app.service.file_has_access_or_download import file_has_access_or_download


def importRecipe(household_id: int, args: dict, overwrite: bool = False):
    recipeNameCount = 0
    recipe = Recipe.find_by_name(household_id, args['name'])
    if recipe and not overwrite:
        recipeNameCount = 1 + \
            Recipe.query.filter(Recipe.household_id == household_id, Recipe.name.ilike(
                args['name'] + " (_%)")).count()
        recipe = None
    if not recipe:
        recipe = Recipe()
        recipe.household_id = household_id
    recipe.name = args['name'] + \
        (f" ({recipeNameCount + 1})" if recipeNameCount > 0 else "")
    recipe.description = args['description']
    if 'time' in args:
        recipe.time = args['time']
    if 'cook_time' in args:
        recipe.cook_time = args['cook_time']
    if 'prep_time' in args:
        recipe.prep_time = args['prep_time']
    if 'yields' in args:
        recipe.yields = args['yields']
    if 'source' in args:
        recipe.source = args['source']
    if 'photo' in args:
        recipe.photo = file_has_access_or_download(args['photo'])

    recipe.save()


    if 'items' in args:
        for recipeItem in args['items']:
            item = Item.find_by_name(household_id, recipeItem['name'])
            if not item:
                item = Item.create_by_name(
                    household_id, recipeItem['name'])
            con = RecipeItems(
                description=recipeItem['description'],
                optional=recipeItem['optional']
            )
            con.item = item
            con.recipe = recipe
            con.save()
    if 'tags' in args:
        for tagName in args['tags']:
            tag = Tag.find_by_name(household_id, tagName)
            if not tag:
                tag = Tag.create_by_name(household_id, tagName)
            con = RecipeTags()
            con.tag = tag
            con.recipe = recipe
            con.save()
