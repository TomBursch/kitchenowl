from datetime import datetime
from typing import Optional, Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, ExpenseCategory, User, File
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Expense(Model, DbModelAuthorizeMixin):
    __tablename__ = "expense"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    amount: Mapped[float] = db.Column(db.Float())
    description: Mapped[str] = db.Column(db.String)
    date: Mapped[datetime] = db.Column(
        db.DateTime, default=datetime.utcnow, nullable=False
    )
    category_id: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("expense_category.id")
    )
    photo: Mapped[str | None] = db.Column(db.String(), db.ForeignKey("file.filename"))
    paid_by_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("user.id"))
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )
    exclude_from_statistics = db.Column(db.Boolean, default=False, nullable=False)

    household: Mapped["Household"] = cast(
        Mapped["Household"], db.relationship("Household", uselist=False, init=False)
    )
    category: Mapped[Optional["ExpenseCategory"]] = cast(
        Mapped["ExpenseCategory"], db.relationship("ExpenseCategory", init=False)
    )
    paid_by: Mapped["User"] = cast(Mapped["User"], db.relationship("User", init=False))
    paid_for: Mapped[List["ExpensePaidFor"]] = cast(
        Mapped[List["ExpensePaidFor"]],
        db.relationship(
            "ExpensePaidFor",
            back_populates="expense",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    photo_file: Mapped["File"] = cast(
        Mapped["File"],
        db.relationship("File", back_populates="expense", uselist=False, init=False),
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict:
        res = super().obj_to_dict(skip_columns, include_columns)
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
    def find_by_name(cls, name) -> Self | None:
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Self | None:
        return (
            cls.query.filter(cls.id == id).join(Expense.category, isouter=True).first()
        )


class ExpensePaidFor(Model):
    __tablename__ = "expense_paid_for"

    expense_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("expense.id"), primary_key=True
    )
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), primary_key=True
    )
    factor: Mapped[int] = db.Column(db.Integer())

    expense: Mapped["Expense"] = cast(
        Mapped["Expense"],
        db.relationship("Expense", back_populates="paid_for", init=False),
    )
    user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship("User", back_populates="expenses_paid_for", init=False),
    )

    def obj_to_user_dict(self):
        res = self.user.obj_to_dict()
        res["factor"] = getattr(self, "factor")
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        return res

    @classmethod
    def find_by_ids(cls, expense_id, user_id) -> Self | None:
        return cls.query.filter(
            cls.expense_id == expense_id, cls.user_id == user_id
        ).first()
