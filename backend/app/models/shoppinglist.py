from typing import Self, List, TYPE_CHECKING
from app import db
from app.helpers import DbModelMixin, DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

if TYPE_CHECKING:
    from app.models import *


class Shoppinglist(db.Model, DbModelMixin, DbModelAuthorizeMixin):
    __tablename__ = "shoppinglist"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))

    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = db.relationship("Household", uselist=False)
    items: Mapped[List["ShoppinglistItems"]] = db.relationship(
        "ShoppinglistItems", cascade="all, delete-orphan"
    )

    history: Mapped[List["History"]] = db.relationship(
        "History", back_populates="shoppinglist", cascade="all, delete-orphan"
    )

    @classmethod
    def getDefault(cls, household_id: int) -> Self:
        return (
            cls.query.filter(cls.household_id == household_id).order_by(cls.id).first()
        )

    def isDefault(self) -> bool:
        return self.id == self.getDefault(self.household_id).id


class ShoppinglistItems(db.Model, DbModelMixin):
    __tablename__ = "shoppinglist_items"

    shoppinglist_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("shoppinglist.id"), primary_key=True
    )
    item_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("item.id"), primary_key=True
    )
    description: Mapped[str] = db.Column(db.String)
    created_by: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )

    item: Mapped["Item"] = db.relationship("Item", back_populates="shoppinglists")
    shoppinglist: Mapped["Shoppinglist"] = db.relationship(
        "Shoppinglist", back_populates="items"
    )
    created_by_user: Mapped["User"] = db.relationship(
        "User", foreign_keys=[created_by], uselist=False
    )

    def obj_to_item_dict(self) -> dict:
        res = self.item.obj_to_dict()
        res["description"] = getattr(self, "description")
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        res["created_by"] = getattr(self, "created_by")
        return res

    @classmethod
    def find_by_ids(cls, shoppinglist_id: int, item_id: int) -> Self:
        return cls.query.filter(
            cls.shoppinglist_id == shoppinglist_id, cls.item_id == item_id
        ).first()
