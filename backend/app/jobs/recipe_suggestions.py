from typing import cast
from sqlalchemy import func
from app.models import Recipe, RecipeHistory
from app import app, db
import datetime

from app.models.recipe_history import Status


def computeRecipeSuggestions(household_id: int):
    historyCount = (
        RecipeHistory.query.with_entities(
            RecipeHistory.recipe_id, func.count().label("count")
        )
        .filter(
            RecipeHistory.status == Status.ADDED,
            RecipeHistory.household_id == household_id,
            RecipeHistory.created_at
            >= datetime.datetime.now(datetime.timezone.utc)
            - datetime.timedelta(days=182),
            RecipeHistory.created_at
            <= datetime.datetime.now(datetime.timezone.utc)
            - datetime.timedelta(days=7),
        )
        .group_by(RecipeHistory.recipe_id)
        .all()
    )
    # 0) reset all suggestion scores
    for r in Recipe.all_from_household(household_id):
        r.suggestion_score = 0
        db.session.add(r)

    # 1) count cooked instances in last six months
    for e in historyCount:
        r = Recipe.find_by_id(e.recipe_id)
        if not r:
            continue
        r.suggestion_score = cast(int, e.count)
        db.session.add(r)

    # commit changes to db
    db.session.commit()
    app.logger.info("computed and stored new suggestion scores")
