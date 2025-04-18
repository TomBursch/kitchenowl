from typing import Self, TYPE_CHECKING, cast
from app import db
from .recipe import Recipe
from .planner import Planner
from sqlalchemy import func
from sqlalchemy.orm import Mapped

import enum

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Recipe
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Status(enum.Enum):
    ADDED = 1
    DROPPED = -1


class RecipeHistory(Model):
    __tablename__ = "recipe_history"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)

    recipe_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("recipe.id"))
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"], db.relationship("Household", uselist=False, init=False)
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship(
            "Recipe", uselist=False, back_populates="recipe_history", init=False
        ),
    )

    status: Mapped[Status] = db.Column(db.Enum(Status))

    @classmethod
    def create_added(cls, recipe: Recipe, household_id: int) -> Self:
        return cls(
            recipe_id=recipe.id,
            status=Status.ADDED,
            household_id=household_id,
        ).save()

    @classmethod
    def create_dropped(cls, recipe: Recipe, household_id: int) -> Self:
        return cls(
            recipe_id=recipe.id,
            status=Status.DROPPED,
            household_id=household_id,
        ).save()

    @classmethod
    def find_added(cls, household_id: int) -> list[Self]:
        return cls.query.filter(
            cls.household_id == household_id, cls.status == Status.ADDED
        ).all()

    @classmethod
    def find_dropped(cls, household_id: int) -> list[Self]:
        return cls.query.filter(
            cls.household_id == household_id, cls.status == Status.DROPPED
        ).all()

    @classmethod
    def find_all(cls, household_id: int) -> list[Self]:
        return cls.query.filter(cls.household_id == household_id).all()

    @classmethod
    def get_recent(cls, household_id: int) -> list[Self]:
        sq = (
            db.session.query(Planner.recipe_id)
            .group_by(Planner.recipe_id)
            .filter(Planner.household_id == household_id)
            .subquery()
            .select()
        )
        sq2 = (
            db.session.query(func.max(cls.id))
            .filter(cls.status == Status.DROPPED, cls.household_id == household_id)
            .filter(cls.recipe_id.notin_(sq))
            .group_by(cls.recipe_id)
            .join(cls.recipe)
            .subquery()
            .select()
        )
        return cls.query.filter(cls.id.in_(sq2)).order_by(cls.id.desc()).limit(9).all()
