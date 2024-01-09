from datetime import timedelta
from app.jobs.recipe_suggestions import computeRecipeSuggestions
from app.config import app, scheduler, celery_app, MESSAGE_BROKER
from celery.schedules import crontab
from app.models import (
    Token,
    Household,
    Shoppinglist,
    Recipe,
    ChallengePasswordReset,
    OIDCRequest,
)
from .item_ordering import findItemOrdering
from .item_suggestions import findItemSuggestions
from .cluster_shoppings import clusterShoppings


if not MESSAGE_BROKER:

    @scheduler.task("cron", id="everyDay", day_of_week="*", hour="3", minute="0")
    def setup_daily():
        with app.app_context():
            daily()

    @scheduler.task("interval", id="every30min", minutes=30)
    def setup_halfHourly():
        with app.app_context():
            halfHourly()

else:
    @celery_app.task
    def dailyTask():
        daily()

    @celery_app.task
    def halfHourlyTask():
        halfHourly()

    @celery_app.on_after_configure.connect
    def setup_periodic_tasks(sender, **kwargs):
        sender.add_periodic_task(
            timedelta(minutes=30), halfHourlyTask, name="every30min"
        )

        sender.add_periodic_task(
            crontab(day_of_week="*", hour=3, minute=0),
            dailyTask,
            name="everyDay",
        )


def daily():
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


def halfHourly():
    # Remove expired Tokens
    Token.delete_expired_access()
    Token.delete_expired_refresh()
    ChallengePasswordReset.delete_expired()
    OIDCRequest.delete_expired()
