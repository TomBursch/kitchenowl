from __future__ import annotations
from typing import Optional, Self, List, TYPE_CHECKING, cast

from sqlalchemy import func
from app import db
from app.helpers import DbModelAuthorizeMixin
from app.models.category import Category
from app.util import description_merger
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, RecipeItems, ShoppinglistItems
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Item(Model, DbModelAuthorizeMixin):
    __tablename__ = "item"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    icon: Mapped[str | None] = db.Column(db.String(128), nullable=True)
    category_id: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("category.id")
    )
    default: Mapped[bool] = db.Column(db.Boolean, default=False)
    default_key: Mapped[str | None] = db.Column(db.String(128))
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
    category: Mapped[Optional["Category"]] = cast(
        Mapped["Category"],
        db.relationship(
            "Category",
        ),
    )

    recipes: Mapped[List["RecipeItems"]] = cast(
        Mapped[List["RecipeItems"]],
        db.relationship(
            "RecipeItems",
            back_populates="item",
            cascade="all, delete-orphan",
        ),
    )
    shoppinglists: Mapped[List["ShoppinglistItems"]] = cast(
        Mapped[List["ShoppinglistItems"]],
        db.relationship(
            "ShoppinglistItems",
            back_populates="item",
            cascade="all, delete-orphan",
        ),
    )

    # determines order of items in the shoppinglist
    ordering = db.Column(db.Integer, server_default="0")
    # frequency of item, used for item suggestions
    support = db.Column(db.Float, server_default="0.0")

    history = db.relationship(
        "History", back_populates="item", cascade="all, delete-orphan"
    )
    antecedents = db.relationship(
        "Association",
        back_populates="antecedent",
        foreign_keys="Association.antecedent_id",
        cascade="all, delete-orphan",
    )
    consequents = db.relationship(
        "Association",
        back_populates="consequent",
        foreign_keys="Association.consequent_id",
        cascade="all, delete-orphan",
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict:
        res = super().obj_to_dict(skip_columns, include_columns)
        if self.category_id:
            category = cast(Category, Category.find_by_id(self.category_id))
            res["category"] = category.obj_to_dict()
        return res

    def obj_to_export_dict(self) -> dict:
        res = {
            "name": self.name,
        }
        if self.icon:
            res["icon"] = self.icon
        if self.category:
            res["category"] = self.category.name
        return res

    def save(self, keepDefault=False) -> Self:
        if not keepDefault:
            self.default = False
        return super().save()

    def merge(self, other: Self) -> None:
        if other.household_id != self.household_id:
            return

        from app.models import RecipeItems
        from app.models import History
        from app.models import ShoppinglistItems

        if not self.default_key and other.default_key:
            self.default_key = other.default_key

        if not self.category_id and other.category_id:
            self.category_id = other.category_id

        if not self.icon and other.icon:
            self.icon = other.icon

        for ri in RecipeItems.query.filter(RecipeItems.item_id == other.id).all():
            ri: RecipeItems
            existingRi = RecipeItems.find_by_ids(ri.recipe_id, self.id)
            if not existingRi:
                ri.item_id = self.id
                db.session.add(ri)
            else:
                existingRi.description = description_merger.merge(
                    existingRi.description, ri.description
                )
                db.session.delete(ri)
                db.session.add(existingRi)

        for si in ShoppinglistItems.query.filter(
            ShoppinglistItems.item_id == other.id
        ).all():
            si: ShoppinglistItems
            existingSi = ShoppinglistItems.find_by_ids(si.shoppinglist_id, self.id)
            if not existingSi:
                si.item_id = self.id
                db.session.add(si)
            else:
                existingSi.description = description_merger.merge(
                    existingSi.description, si.description
                )
                db.session.delete(si)
                db.session.add(existingSi)

        for history in History.query.filter(History.item_id == other.id).all():
            history.item_id = self.id
            db.session.add(history)

        try:
            db.session.add(self)
            db.session.commit()
            other.delete()
        except Exception as e:
            db.session.rollback()
            raise e

    @classmethod
    def create_by_name(
        cls, household_id: int, name: str, default: bool = False
    ) -> Self:
        return cls(
            name=name.strip(),
            default=default,
            household_id=household_id,
        ).save()

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self | None:
        name = name.strip()
        return cls.query.filter(
            cls.household_id == household_id, func.lower(cls.name) == func.lower(name)
        ).first()

    @classmethod
    def find_by_default_key(cls, household_id: int, default_key: str) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id, cls.default_key == default_key
        ).first()

    @classmethod
    def find_name_starts_with(cls, household_id: int, starts_with: str) -> Self | None:
        starts_with = starts_with.strip()
        return cls.query.filter(
            cls.household_id == household_id,
            func.lower(cls.name).like(func.lower(starts_with) + "%"),
        ).first()

    @classmethod
    def search_name(cls, name: str, household_id: int) -> list[Self]:
        item_count = 11
        if "postgresql" in db.engine.name:
            return (
                cls.query.filter(
                    cls.household_id == household_id,
                    func.levenshtein(
                        func.lower(func.substring(cls.name, 1, len(name))), name.lower()
                    )
                    < 4,
                )
                .order_by(
                    func.levenshtein(
                        func.lower(func.substring(cls.name, 1, len(name))), name.lower()
                    ),
                    cls.support.desc(),
                )
                .limit(item_count)
                .all()
            )

        found = []

        # name is a regex
        if "*" in name or "?" in name or "%" in name or "_" in name:
            looking_for = name.replace("*", "%").replace("?", "_")
            found = (
                cls.query.filter(
                    cls.name.ilike(looking_for), cls.household_id == household_id
                )
                .order_by(cls.support.desc())
                .limit(item_count)
                .all()
            )
            return found

        # name is no regex
        starts_with = "{0}%".format(name)
        contains = "%{0}%".format(name)
        one_error = []
        for index in range(len(name)):
            name_one_error = name[:index] + "_" + name[index + 1 :]
            one_error.append("%{0}%".format(name_one_error))

        for looking_for in [starts_with, contains] + one_error:
            res = (
                cls.query.filter(
                    cls.name.ilike(looking_for), cls.household_id == household_id
                )
                .order_by(cls.support.desc(), cls.name)
                .all()
            )
            for r in res:
                if r not in found:
                    found.append(r)
                    item_count -= 1
                    if item_count <= 0:
                        return found
        return found
