from datetime import datetime
from typing import Self, List, TYPE_CHECKING
from app import db
from app.helpers import DbModelMixin, DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

if TYPE_CHECKING:
    from app.models import *


class Expense(db.Model, DbModelMixin, DbModelAuthorizeMixin):
    __tablename__ = "expense"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    amount: Mapped[float] = db.Column(db.Float())
    description: Mapped[str] = db.Column(db.String)
    date: Mapped[datetime] = db.Column(
        db.DateTime, default=datetime.utcnow, nullable=False
    )
    category_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("expense_category.id")
    )
    photo: Mapped[str] = db.Column(db.String(), db.ForeignKey("file.filename"))
    paid_by_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("user.id"))
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )
    exclude_from_statistics = db.Column(db.Boolean, default=False, nullable=False)

    household: Mapped["Household"] = db.relationship("Household", uselist=False)
    category: Mapped["ExpenseCategory"] = db.relationship("ExpenseCategory")
    paid_by: Mapped["User"] = db.relationship("User")
    paid_for: Mapped[List["Household"]] = db.relationship(
        "ExpensePaidFor", back_populates="expense", cascade="all, delete-orphan"
    )
    photo_file: Mapped["File"] = db.relationship(
        "File", back_populates="expense", uselist=False
    )

    def obj_to_dict(self) -> dict:
        res = super().obj_to_dict()
        if self.photo_file:
            res["photo_hash"] = self.photo_file.blur_hash
        return res

    def obj_to_full_dict(self) -> dict:
        res = self.obj_to_dict()
        paidFor = (
            ExpensePaidFor.query.filter(ExpensePaidFor.expense_id == self.id)
            .join(ExpensePaidFor.user)
            .order_by(ExpensePaidFor.expense_id)
            .all()
        )
        res["paid_for"] = [e.obj_to_dict() for e in paidFor]
        if self.category:
            res["category"] = self.category.obj_to_full_dict()
        return res

    def obj_to_export_dict(self) -> dict:
        res = {
            "name": self.name,
            "amount": self.amount,
            "date": self.date,
            "photo": self.photo,
            "paid_for": [
                {"factor": e.factor, "username": e.user.username} for e in self.paid_for
            ],
            "paid_by": self.paid_by.username,
        }
        if self.category:
            res["category"] = self.category.obj_to_export_dict()
        return res

    @classmethod
    def find_by_name(cls, name) -> Self:
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Self:
        return (
            cls.query.filter(cls.id == id).join(Expense.category, isouter=True).first()
        )


class ExpensePaidFor(db.Model, DbModelMixin):
    __tablename__ = "expense_paid_for"

    expense_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("expense.id"), primary_key=True
    )
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), primary_key=True
    )
    factor: Mapped[int] = db.Column(db.Integer())

    expense: Mapped["Expense"] = db.relationship("Expense", back_populates="paid_for")
    user: Mapped["User"] = db.relationship("User", back_populates="expenses_paid_for")

    def obj_to_user_dict(self):
        res = self.user.obj_to_dict()
        res["factor"] = getattr(self, "factor")
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        return res

    @classmethod
    def find_by_ids(cls, expense_id, user_id) -> list[Self]:
        return cls.query.filter(
            cls.expense_id == expense_id, cls.user_id == user_id
        ).first()
