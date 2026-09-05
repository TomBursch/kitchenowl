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
from .schemas import ImportSchema
from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required

importBP = Blueprint("import", __name__)


@importBP.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(ImportSchema)
def importData(args: ImportSchema, household_id):
    household = Household.find_by_id(household_id)
    if not household:
        return

    app.logger.info("Starting import...")

    t0 = time.time()
    if args.items:
        for item in args.items:
            importItem(household, item)

    if args.recipes:
        for recipe in args.recipes:
            importRecipe(
                household_id,
                recipe,
                args.recipe_overwrite if args.recipe_overwrite is not None else False,
            )

    if args.expenses:
        for expense in args.expenses:
            importExpense(household, expense)
        recalculateBalances(household.id)

    if args.shoppinglists:
        for shoppinglist in args.shoppinglists:
            importShoppinglist(household, shoppinglist)

    app.logger.info(f"Import took: {(time.time() - t0):.3f}s")
    return jsonify({"msg": "DONE"})
