from __future__ import annotations
from typing import Self, List, TYPE_CHECKING
from app import db
from app.helpers import DbModelMixin, DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

if TYPE_CHECKING:
    from app.models import *


class ExpenseCategory(db.Model, DbModelMixin, DbModelAuthorizeMixin):
    __tablename__ = "expense_category"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    color: Mapped[int] = db.Column(db.BigInteger)
    budget: Mapped[float] = db.Column(db.Float())
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False
    )

    household: Mapped["Household"] = db.relationship("Household", uselist=False)
    expenses: Mapped[List["Household"]] = db.relationship(
        "Expense", back_populates="category"
    )

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    def obj_to_export_dict(self) -> dict:
        return {
            "name": self.name,
            "color": self.color,
        }

    def merge(self, other: Self) -> None:
        if self.household_id != other.household_id:
            return

        from app.models import Expense

        for expense in Expense.query.filter(Expense.category_id == other.id).all():
            expense.category_id = self.id
            db.session.add(expense)

        try:
            db.session.commit()
            other.delete()
        except Exception as e:
            db.session.rollback()
            raise e

    @classmethod
    def find_by_name(cls, houshold_id: int, name: str) -> Self:
        return cls.query.filter(
            cls.name == name, cls.household_id == houshold_id
        ).first()

    @classmethod
    def find_by_id(cls, id: int) -> Self:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def delete_by_name(cls, household_id: int, name: str):
        mc = cls.find_by_name(household_id, name)
        if mc:
            mc.delete()
