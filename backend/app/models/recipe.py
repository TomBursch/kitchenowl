from __future__ import annotations
from typing import Any, Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from .item import Item
from .tag import Tag
from .planner import Planner
from random import randint
from sqlalchemy.orm import Mapped
from datetime import datetime, timedelta

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, RecipeHistory, File
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


def is_within_next_7_days(target_date: datetime) -> bool:
    # Get the current date and time
    now = datetime.now()

    # Calculate the date 7 days from now
    seven_days_later = now + timedelta(days=7)

    # Check if the target date is within the next 7 days
    return now <= target_date <= seven_days_later


def transform_cooking_date_to_day(cooking_date: datetime) -> int:
    if is_within_next_7_days(cooking_date):
        return cooking_date.weekday()
    return -1


class Recipe(Model, DbModelAuthorizeMixin):
    __tablename__ = "recipe"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    description: Mapped[str] = db.Column(db.String())
    photo: Mapped[str | None] = db.Column(db.String(), db.ForeignKey("file.filename"))
    time: Mapped[int] = db.Column(db.Integer)
    cook_time: Mapped[int] = db.Column(db.Integer)
    prep_time: Mapped[int] = db.Column(db.Integer)
    yields: Mapped[int] = db.Column(db.Integer)
    source: Mapped[str] = db.Column(db.String())
    public: Mapped[bool] = db.Column(db.Boolean(), nullable=False, default=False)
    suggestion_score: Mapped[int] = db.Column(db.Integer, server_default="0")
    suggestion_rank: Mapped[int] = db.Column(db.Integer, server_default="0")
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
    recipe_history: Mapped[List["RecipeHistory"]] = cast(
        Mapped[List["RecipeHistory"]],
        db.relationship(
            "RecipeHistory",
            back_populates="recipe",
            cascade="all, delete-orphan",
        ),
    )
    items: Mapped[List["RecipeItems"]] = cast(
        Mapped[List["RecipeItems"]],
        db.relationship(
            "RecipeItems",
            back_populates="recipe",
            cascade="all, delete-orphan",
            lazy="selectin",
            order_by="RecipeItems._name",
        ),
    )
    tags: Mapped[List["RecipeTags"]] = cast(
        Mapped[List["RecipeTags"]],
        db.relationship(
            "RecipeTags",
            back_populates="recipe",
            cascade="all, delete-orphan",
            lazy="selectin",
            order_by="RecipeTags._name",
        ),
    )
    plans: Mapped[List["Planner"]] = cast(
        Mapped[List["Planner"]],
        db.relationship(
            "Planner",
            back_populates="recipe",
            cascade="all, delete-orphan",
            lazy="selectin",
        ),
    )
    photo_file: Mapped["File"] = cast(
        Mapped["File"],
        db.relationship(
            "File",
            back_populates="recipe",
            uselist=False,
            lazy="selectin",
        ),
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = super().obj_to_dict(skip_columns, include_columns)
        res["planned"] = len(self.plans) > 0
        res["planned_days"] = [
            transform_cooking_date_to_day(plan.cooking_date)
            for plan in self.plans
            if (plan.cooking_date > datetime.min)
            and is_within_next_7_days(plan.cooking_date)
        ]
        res["planned_cooking_dates"] = [
            plan.cooking_date for plan in self.plans if plan.cooking_date > datetime.min
        ]
        if self.photo_file:
            res["photo_hash"] = self.photo_file.blur_hash

        for column_name in skip_columns or []:
            if column_name in res:
                del res[column_name]
        return res

    def obj_to_full_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = self.obj_to_dict(skip_columns, include_columns)
        res["items"] = [e.obj_to_item_dict() for e in self.items]
        res["tags"] = [e.obj_to_item_dict() for e in self.tags]
        res["household"] = self.household.obj_to_public_dict()

        for column_name in skip_columns or []:
            if column_name in res:
                del res[column_name]
        return res

    def obj_to_public_dict(self) -> dict[str, Any]:
        res = self.obj_to_full_dict(
            skip_columns=[
                "planned_days",
                "planned_cooking_dates",
                "planned",
            ]
        )
        return res

    def obj_to_export_dict(self) -> dict[str, Any]:
        res = {
            "name": self.name,
            "description": self.description,
            "time": self.time,
            "photo": self.photo,
            "cook_time": self.cook_time,
            "prep_time": self.prep_time,
            "yields": self.yields,
            "source": self.source,
            "items": [
                {
                    "name": e.item.name,
                    "description": e.description,
                    "optional": e.optional,
                }
                for e in self.items
            ],
            "tags": [e.tag.name for e in self.tags],
        }
        return res

    @classmethod
    def compute_suggestion_ranking(cls, household_id: int):
        # reset all suggestion ranks
        for r in cls.query.filter(cls.household_id == household_id).all():
            r.suggestion_rank = 0
            db.session.add(r)
        # get all recipes with positive suggestion_score
        recipes = cls.query.filter(
            cls.household_id == household_id, cls.suggestion_score != 0
        ).all()
        # compute the initial sum of all suggestion_scores
        suggestion_sum = 0
        for r in recipes:
            suggestion_sum += r.suggestion_score
        # iteratively assign increasing suggestion rank to random recipes weighted by their score
        current_rank = 1
        while len(recipes) > 0:
            choose = randint(1, suggestion_sum)
            to_be_removed = -1
            for i, r in enumerate(recipes):
                choose -= r.suggestion_score
                if choose <= 0:
                    r.suggestion_rank = current_rank
                    current_rank += 1
                    suggestion_sum -= r.suggestion_score
                    to_be_removed = i
                    db.session.add(r)
                    break
            recipes.pop(to_be_removed)
        db.session.commit()

    @classmethod
    def find_suggestions(
        cls,
        household_id: int,
    ) -> list[Self]:
        sq = (
            db.session.query(Planner.recipe_id)
            .group_by(Planner.recipe_id)
            .scalar_subquery()
        )
        return (
            cls.query.filter(cls.household_id == household_id, cls.id.notin_(sq))
            .filter(cls.suggestion_rank > 0)  # noqa
            .order_by(cls.suggestion_rank)
            .all()
        )

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id, cls.name == name
        ).first()

    @classmethod
    def search_name(cls, household_id: int, name: str) -> list[Self]:
        if "*" in name or "_" in name:
            looking_for = name.replace("_", "__").replace("*", "%").replace("?", "_")
        else:
            looking_for = "%{0}%".format(name)
        return (
            cls.query.filter(
                cls.household_id == household_id, cls.name.ilike(looking_for)
            )
            .order_by(cls.name)
            .all()
        )

    @classmethod
    def all_by_name_with_filter(
        cls, household_id: int, filter: list[str]
    ) -> list[Self]:
        sq = (
            db.session.query(RecipeTags.recipe_id)
            .join(RecipeTags.tag)
            .filter(Tag.name.in_(filter))
            .subquery()
        )
        return (
            db.session.query(cls)
            .filter(cls.household_id == household_id, cls.id.in_(sq))
            .order_by(cls.name)
            .all()
        )


class RecipeItems(Model):
    __tablename__ = "recipe_items"

    recipe_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("recipe.id"), primary_key=True
    )
    item_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("item.id"), primary_key=True
    )
    description: Mapped[str] = db.Column("description", db.String())
    optional: Mapped[bool] = db.Column("optional", db.Boolean)

    item: Mapped["Item"] = cast(
        Mapped["Item"],
        db.relationship(
            "Item",
            back_populates="recipes",
            lazy="joined",
        ),
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship(
            "Recipe",
            back_populates="items",
        ),
    )

    _name: Mapped[str] = db.column_property(
        db.select(Item.name).where(Item.id == item_id).scalar_subquery()
    )

    def obj_to_item_dict(self) -> dict[str, Any]:
        res = self.item.obj_to_dict()
        res["description"] = getattr(self, "description")
        res["optional"] = getattr(self, "optional")
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        return res

    def obj_to_recipe_dict(self) -> dict[str, Any]:
        res = self.recipe.obj_to_dict()
        res["items"] = [
            {
                "id": getattr(self, "item_id"),
                "description": getattr(self, "description"),
                "optional": getattr(self, "optional"),
            }
        ]
        return res

    @classmethod
    def find_by_ids(cls, recipe_id: int, item_id: int) -> Self | None:
        return cls.query.filter(
            cls.recipe_id == recipe_id, cls.item_id == item_id
        ).first()


class RecipeTags(Model):
    __tablename__ = "recipe_tags"

    recipe_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("recipe.id"), primary_key=True
    )
    tag_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("tag.id"), primary_key=True
    )

    tag: Mapped["Tag"] = cast(
        Mapped["Tag"],
        db.relationship(
            "Tag",
            back_populates="recipes",
        ),
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship(
            "Recipe",
            back_populates="tags",
            lazy="joined",
        ),
    )

    _name: Mapped[str] = db.column_property(
        db.select(Tag.name).where(Tag.id == tag_id).scalar_subquery()
    )

    def obj_to_item_dict(self) -> dict[str, Any]:
        res = self.tag.obj_to_dict()
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        return res

    @classmethod
    def find_by_ids(cls, recipe_id: int, tag_id: int) -> Self | None:
        return cls.query.filter(
            cls.recipe_id == recipe_id, cls.tag_id == tag_id
        ).first()
