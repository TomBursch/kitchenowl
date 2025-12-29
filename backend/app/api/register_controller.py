from flask import Blueprint
from app.config import app, api_spec
import app.controller as api

# Register Endpoints
apiv1 = Blueprint("api", __name__)

api.household.register_blueprint(api.export, url_prefix="/<int:household_id>/export")
api.household.register_blueprint(api.importBP, url_prefix="/<int:household_id>/import")
api.household.register_blueprint(
    api.categoryHousehold, url_prefix="/<int:household_id>/category"
)
api.household.register_blueprint(
    api.plannerHousehold, url_prefix="/<int:household_id>/planner"
)
api.household.register_blueprint(
    api.expenseHousehold, url_prefix="/<int:household_id>/expense"
)
api.household.register_blueprint(
    api.loyaltyCardHousehold, url_prefix="/<int:household_id>/loyalty-card"
)
api.household.register_blueprint(
    api.itemHousehold, url_prefix="/<int:household_id>/item"
)
api.household.register_blueprint(
    api.recipeHousehold, url_prefix="/<int:household_id>/recipe"
)
api.household.register_blueprint(
    api.shoppinglistHousehold, url_prefix="/<int:household_id>/shoppinglist"
)
api.household.register_blueprint(api.tagHousehold, url_prefix="/<int:household_id>/tag")

apiv1.register_blueprint(
    api.health, url_prefix="/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V"
)
apiv1.register_blueprint(api.auth, url_prefix="/auth")
apiv1.register_blueprint(api.household, url_prefix="/household")
apiv1.register_blueprint(api.category, url_prefix="/category")
apiv1.register_blueprint(api.expense, url_prefix="/expense")
apiv1.register_blueprint(api.loyaltyCard, url_prefix="/loyalty-card")
apiv1.register_blueprint(api.item, url_prefix="/item")
apiv1.register_blueprint(api.onboarding, url_prefix="/onboarding")
apiv1.register_blueprint(api.recipe, url_prefix="/recipe")
apiv1.register_blueprint(api.settings, url_prefix="/settings")
apiv1.register_blueprint(api.shoppinglist, url_prefix="/shoppinglist")
apiv1.register_blueprint(api.tag, url_prefix="/tag")
apiv1.register_blueprint(api.user, url_prefix="/user")
apiv1.register_blueprint(api.upload, url_prefix="/upload")
apiv1.register_blueprint(api.analytics, url_prefix="/analytics")
apiv1.register_blueprint(api.reportBlueprint, url_prefix="/report")

app.register_blueprint(apiv1, url_prefix="/api")


with app.test_request_context():
    for rule in app.url_map.iter_rules():
        api_spec.path(view=app.view_functions[rule.endpoint])
