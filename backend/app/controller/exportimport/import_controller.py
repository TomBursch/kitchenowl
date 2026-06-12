import time
from app.config import app
from app.models import Household
from app.service.importServices import (
    importItem,
    importRecipe,
    importExpense,
    importShoppinglist,
)
from app.service.recalculate_balances import recalculateBalances
from .schemas import ImportSchema, RecipeImportCommitSchema
from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint, request, abort
from flask_jwt_extended import jwt_required
from app.service.recipe_import_service import (
    preview_recipe_import,
    commit_recipe_import,
    get_recipe_import_job,
)

importBP = Blueprint("import", __name__)


@importBP.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(ImportSchema)
def importData(args, household_id):
    household = Household.find_by_id(household_id)
    if not household:
        return

    app.logger.info("Starting import...")

    t0 = time.time()
    if "items" in args:
        for item in args["items"]:
            importItem(household, item)

    if "recipes" in args:
        for recipe in args["recipes"]:
            importRecipe(
                household_id,
                recipe,
                args["recipe_overwrite"] if "recipe_overwrite" in args else False,
            )

    if "expenses" in args:
        for expense in args["expenses"]:
            importExpense(household, expense)
        recalculateBalances(household.id)

    if "shoppinglists" in args:
        for shoppinglist in args["shoppinglists"]:
            importShoppinglist(household, shoppinglist)

    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")
    return jsonify({"msg": "DONE"})


@importBP.route("/recipes/preview", methods=["POST"])
@jwt_required()
@authorize_household()
def previewRecipeImport(household_id):
    if "file" not in request.files:
        return jsonify({"msg": "missing file"}), 400
    file = request.files["file"]
    if not file.filename:
        return jsonify({"msg": "missing filename"}), 400
    filename = file.filename.lower()
    if not (
        filename.endswith(".json")
        or filename.endswith(".zip")
        or filename.endswith(".paprikarecipes")
    ):
        return jsonify({"msg": "unsupported file"}), 400

    data = file.read()
    res = preview_recipe_import(household_id, data, filename)
    return jsonify(res)


@importBP.route("/recipes/commit", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(RecipeImportCommitSchema)
def commitRecipeImport(args, household_id):
    decisions = args.get("decisions", {})
    res = commit_recipe_import(household_id, args["token"], decisions)
    return jsonify(res)


@importBP.route("/recipes/commit/<token>", methods=["GET"])
@jwt_required()
@authorize_household()
def getRecipeImportCommitStatus(household_id, token):
    res = get_recipe_import_job(token)
    if res is None:
        abort(404, description="Import job not found or token has expired")
    return jsonify(res)
