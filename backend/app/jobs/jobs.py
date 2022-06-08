from app.jobs.recipe_suggestions import findMealInstancesFromHistory, computeRecipeSuggestions
from app import app, scheduler
from app.models import Token
from .item_ordering import findItemOrdering
from .item_suggestions import findItemSuggestions
from .cluster_shoppings import clusterShoppings


@app.before_first_request
def load_jobs():
    # for debugging:
    # @scheduler.task('interval', id='test', seconds=5)
    # def test():
    #     app.logger.info("--- test analysis is starting ---")
    #     # recipe planner tasks
    #     meal_instances = findMealInstancesFromHistory()
    #     computeRecipeSuggestions(meal_instances)
    #     app.logger.info("--- test analysis is completed ---")

    @scheduler.task('cron', id='everyDay', day_of_week='*', hour='3')
    def daily():
        app.logger.info("--- daily analysis is starting ---")
        # shopping tasks
        shopping_instances = clusterShoppings()
        findItemOrdering(shopping_instances)
        findItemSuggestions(shopping_instances)
        # recipe planner tasks
        meal_instances = findMealInstancesFromHistory()
        computeRecipeSuggestions(meal_instances)
        app.logger.info("--- daily analysis is completed ---")

    @scheduler.task('interval', id='every30min', minutes=30)
    def halfHourly():
        # Remove expired Tokens
        Token.delete_expired_access()
        Token.delete_expired_refresh()
