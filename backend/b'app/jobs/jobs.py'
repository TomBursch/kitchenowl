from app import app, scheduler
from .itemOrdering import findItemOrdering
from .itemSuggestions import findItemSuggestions
from .clusterShoppings import clusterShoppings


@app.before_first_request
def load_jobs():
    # for debugging:
    # @scheduler.task('interval', id='test', seconds=5)
    # def test():
    #     app.logger.info("--- test analysis is starting ---")
    #     shopping_instances = clusterShoppings()
    #     if(shopping_instances):
    #         findItemOrdering(shopping_instances)
    #         findItemSuggestions(shopping_instances)
    #     app.logger.info("--- test analysis is completed ---")

    @scheduler.task('cron', id='everyDay', day_of_week='*', hour='3')
    def daily():
        app.logger.info("--- daily analysis is starting ---")
        shopping_instances = clusterShoppings()
        findItemOrdering(shopping_instances)
        findItemSuggestions(shopping_instances)
        app.logger.info("--- daily analysis is completed ---")
