from __future__ import annotations
from typing import Self, TYPE_CHECKING
from app import db
from app.helpers import DbModelMixin, DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped
from datetime import datetime

if TYPE_CHECKING:
    from app.models import *


class Planner(db.Model, DbModelMixin, DbModelAuthorizeMixin):
    __tablename__ = "planner"

    recipe_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("recipe.id"), primary_key=True)
    when: Mapped[datetime] =  db.Column(db.DateTime,  primary_key=True)
    yields: Mapped[int] = db.Column(db.Integer)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )
    

    household: Mapped["Household"] = db.relationship("Household", uselist=False)
    recipe: Mapped["Recipe"] = db.relationship("Recipe", back_populates="plans")

    def obj_to_full_dict(self) -> dict:
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
            cls.query.filter(cls.household_id == household_id).order_by(cls.when).all()
        )


    @classmethod
    def find_by_datetime(cls, household_id: int, recipe_id: int, when: datetime) -> Self:
        return cls.query.filter(
            cls.household_id == household_id, cls.recipe_id == recipe_id, cls.when == when
        ).first()