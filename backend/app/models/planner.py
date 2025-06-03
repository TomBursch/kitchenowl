from __future__ import annotations
from typing import Any, Self, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped
from sqlalchemy import func
from datetime import datetime, date

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Recipe
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Planner(Model, DbModelAuthorizeMixin):
    __tablename__ = "planner"

    recipe_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("recipe.id"), primary_key=True
    )
    cooking_date: Mapped[datetime] = db.Column(db.DateTime, primary_key=True)
    yields: Mapped[int] = db.Column(db.Integer)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship(
            "Household",
            uselist=False,
        ),
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship(
            "Recipe",
            back_populates="plans",
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = self.obj_to_dict()
        res["recipe"] = self.recipe.obj_to_full_dict()
        return res

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        """
        Return all instances of model
        IMPORTANT: requires household_id column
        """
        return (
            cls.query.filter(cls.household_id == household_id)
            .order_by(cls.cooking_date)
            .all()
        )

    @classmethod
    def find_by_datetime(
        cls, household_id: int, recipe_id: int, cooking_date: date
    ) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id,
            cls.recipe_id == recipe_id,
            func.date(cls.cooking_date) == cooking_date,
        ).first()
