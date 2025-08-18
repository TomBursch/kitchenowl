from datetime import timedelta
from typing import TYPE_CHECKING, cast
from app.jobs.recipe_suggestions import computeRecipeSuggestions
from app.config import app, scheduler, celery_app
from celery.schedules import crontab
from app.models import (
    Token,
    Household,
    Shoppinglist,
    Recipe,
    ChallengePasswordReset,
    OIDCRequest,
)
from app.service.delete_unused import deleteEmptyHouseholds, deleteUnusedFiles
from .item_ordering import findItemOrdering
from .item_suggestions import findItemSuggestions
from .cluster_shoppings import clusterShoppings

if TYPE_CHECKING:
    from celery.utils.dispatch import Signal

if scheduler is not None:

    @scheduler.task("cron", id="everyMonth", day="2", hour="0", minute="0")
    def setup_monthly():
        with app.app_context():
            monthly()

    @scheduler.task("cron", id="everyDay", day_of_week="*", hour="3", minute="0")
    def setup_daily():
        with app.app_context():
            daily()

    @scheduler.task("interval", id="every30min", minutes=30)
    def setup_halfHourly():
        with app.app_context():
            halfHourly()


if celery_app is not None:

    @celery_app.task
    def monthlyTask():
        monthly()

    @celery_app.task
    def dailyTask():
        daily()

    @celery_app.task
    def halfHourlyTask():
        halfHourly()

    @cast(
        "Signal",
        celery_app.on_after_configure,
    ).connect
    def setup_periodic_tasks(sender, **kwargs):
        sender.add_periodic_task(
            timedelta(minutes=30), halfHourlyTask, name="every30min"
        )

        sender.add_periodic_task(
            crontab(day_of_week="*", hour=3, minute=0),
            dailyTask,
            name="everyDay",
        )

        sender.add_periodic_task(
            crontab(day_of_month="2", hour=0, minute=0),
            monthlyTask,
            name="everyMonth",
        )


def monthly():
    deleteEmptyHouseholds()
    deleteUnusedFiles()


def daily():
    app.logger.info("--- daily analysis is starting ---")
    # task for all households
    for household in Household.all():
        # shopping tasks
        shopping_instances = clusterShoppings(
            cast(
                Shoppinglist,
                Shoppinglist.query.filter(
                    Shoppinglist.household_id == household.id
                ).first(),
            ).id
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
