from app.jobs.recipe_suggestions import computeRecipeSuggestions
from app import app, scheduler
from app.models import Token, Household, Shoppinglist, Recipe
from .item_ordering import findItemOrdering
from .item_suggestions import findItemSuggestions
from .cluster_shoppings import clusterShoppings


# # for debugging run: FLASK_DEBUG=True python manage.py


@scheduler.task("cron", id="everyDay", day_of_week="*", hour="3")
def daily():
    with app.app_context():
        app.logger.info("--- daily analysis is starting ---")
        # task for all households
        for household in Household.all():
            # shopping tasks
            shopping_instances = clusterShoppings(
                Shoppinglist.query.filter(Shoppinglist.household_id == household.id)
                .first()
                .id
            )
            if shopping_instances:
                findItemOrdering(shopping_instances)
                findItemSuggestions(shopping_instances)
            # recipe planner tasks
            computeRecipeSuggestions(household.id)
            Recipe.compute_suggestion_ranking(household.id)

        app.logger.info("--- daily analysis is completed ---")


@scheduler.task("interval", id="every30min", minutes=30)
def halfHourly():
    with app.app_context():
        # Remove expired Tokens
        Token.delete_expired_access()
        Token.delete_expired_refresh()
