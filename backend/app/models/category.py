from __future__ import annotations
from typing import Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Item
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Category(Model, DbModelAuthorizeMixin):
    __tablename__ = "category"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    default: Mapped[bool] = db.Column(db.Boolean, default=False)
    default_key: Mapped[str | None] = db.Column(db.String(128))
    ordering: Mapped[int] = db.Column(db.Integer, default=0)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"], db.relationship("Household", uselist=False, init=False)
    )
    items: Mapped[List["Item"]] = cast(
        Mapped[List["Item"]],
        db.relationship("Item", back_populates="category", init=False),
    )

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def all_by_ordering(cls, household_id: int):
        return (
            cls.query.filter(cls.household_id == household_id)
            .order_by(cls.ordering, cls.name)
            .all()
        )

    @classmethod
    def create_by_name(
        cls, household_id: int, name, default: bool = False, default_key: str | None = None
    ) -> Self:
        return cls(
            name=name,
            default=default,
            default_key=default_key,
            household_id=household_id,
        ).save()

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self | None:
        return cls.query.filter(
            cls.name == name, cls.household_id == household_id
        ).first()

    @classmethod
    def find_by_default_key(cls, household_id: int, default_key: str) -> Self | None:
        return cls.query.filter(
            cls.default_key == default_key, cls.household_id == household_id
        ).first()

    def reorder(self, newIndex: int):
        cls = self.__class__

        l: list[Self] = (
            cls.query.filter(cls.household_id == self.household_id)
            .order_by(cls.ordering, cls.name)
            .all()
        )

        self.ordering = min(newIndex, len(l) - 1)

        oldIndex = list(map(lambda x: x.id, l)).index(self.id)
        if oldIndex < 0:
            raise Exception()  # Something went wrong
        e = l.pop(oldIndex)

        l.insert(self.ordering, e)

        for i, category in enumerate(l):
            category.ordering = i

        try:
            db.session.add_all(l)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e

    def merge(self, other: Self) -> None:
        if self.household_id != other.household_id:
            return

        from app.models import Item

        if not self.default_key and other.default_key:
            self.default_key = other.default_key
            self.default = other.default

        for item in Item.query.filter(Item.category_id == other.id).all():
            item.category_id = self.id
            db.session.add(item)

        try:
            db.session.add(self)
            db.session.commit()
            other.delete()
        except Exception as e:
            db.session.rollback()
            raise e

        self.reorder(self.ordering)
