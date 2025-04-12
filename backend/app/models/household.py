from typing import Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers.db_list_type import DbListType
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import (
        Item,
        Shoppinglist,
        Category,
        Recipe,
        Tag,
        Expense,
        ExpenseCategory,
        User,
        File,
    )
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Household(Model):
    __tablename__ = "household"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128), nullable=False)
    photo: Mapped[str | None] = db.Column(db.String(), db.ForeignKey("file.filename"))
    language: Mapped[str] = db.Column(db.String())
    planner_feature: Mapped[bool] = db.Column(
        db.Boolean(), nullable=False, default=True
    )
    expenses_feature: Mapped[bool] = db.Column(
        db.Boolean(), nullable=False, default=True
    )

    view_ordering: Mapped[List] = db.Column(DbListType(), default=list())

    items: Mapped[List["Item"]] = cast(
        Mapped[List["Item"]],
        db.relationship(
            "Item", back_populates="household", cascade="all, delete-orphan", init=False
        ),
    )
    shoppinglists: Mapped[List["Shoppinglist"]] = cast(
        Mapped[List["Shoppinglist"]],
        db.relationship(
            "Shoppinglist",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    categories: Mapped[List["Category"]] = cast(
        Mapped[List["Category"]],
        db.relationship(
            "Category",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    recipes: Mapped[List["Recipe"]] = cast(
        Mapped[List["Recipe"]],
        db.relationship(
            "Recipe",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    tags: Mapped[List["Tag"]] = cast(
        Mapped[List["Tag"]],
        db.relationship(
            "Tag", back_populates="household", cascade="all, delete-orphan", init=False
        ),
    )
    expenses: Mapped[List["Expense"]] = cast(
        Mapped[List["Expense"]],
        db.relationship(
            "Expense",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    expenseCategories: Mapped[List["ExpenseCategory"]] = cast(
        Mapped[List["ExpenseCategory"]],
        db.relationship(
            "ExpenseCategory",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    member: Mapped[List["HouseholdMember"]] = cast(
        Mapped[List["HouseholdMember"]],
        db.relationship(
            "HouseholdMember",
            back_populates="household",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    photo_file: Mapped["File"] = cast(
        Mapped["File"],
        db.relationship("File", back_populates="household", uselist=False, init=False),
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict:
        res = super().obj_to_dict(skip_columns, include_columns)
        res["member"] = [m.obj_to_user_dict() for m in getattr(self, "member")]
        res["default_shopping_list"] = self.shoppinglists[0].obj_to_dict()
        if self.photo_file:
            res["photo_hash"] = self.photo_file.blur_hash
        return res

    def obj_to_public_dict(self) -> dict:
        res = super().obj_to_dict(include_columns=["id", "name", "photo", "language"])
        if self.photo_file:
            res["photo_hash"] = self.photo_file.blur_hash
        return res

    def obj_to_export_dict(self) -> dict:
        return {
            "name": self.name,
            "language": self.language,
            "view_ordering": self.view_ordering,
            "planner_feature": self.planner_feature,
            "expenses_feature": self.expenses_feature,
            "member": [m.user.username for m in getattr(self, "member")],
            "shoppinglists": [s.name for s in self.shoppinglists],
            "recipes": [s.obj_to_export_dict() for s in self.recipes],
            "items": [s.obj_to_export_dict() for s in self.items],
            "expenses": [s.obj_to_export_dict() for s in self.expenses],
        }


class HouseholdMember(Model):
    __tablename__ = "household_member"

    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), primary_key=True
    )
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), primary_key=True
    )

    owner: Mapped[bool] = db.Column(db.Boolean(), default=False, nullable=False)
    admin: Mapped[bool] = db.Column(db.Boolean(), default=True, nullable=False)

    expense_balance: Mapped[float] = db.Column(db.Float(), default=0, nullable=False)

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship("Household", back_populates="member", init=False),
    )
    user: Mapped["User"] = cast(
        Mapped["User"], db.relationship("User", back_populates="households", init=False)
    )

    def obj_to_user_dict(self) -> dict:
        res = self.user.obj_to_dict()
        res["owner"] = getattr(self, "owner")
        res["admin"] = getattr(self, "admin")
        res["expense_balance"] = getattr(self, "expense_balance")
        return res

    def delete(self):
        if self.owner:
            newOwner = next(
                (m for m in self.household.member if m.admin and m != self),
                next((m for m in self.household.member if m != self), None),
            )
            if newOwner:
                newOwner.admin = True
                newOwner.owner = True
                newOwner.save()
            super().delete()
        else:
            super().delete()

    @classmethod
    def find_by_ids(cls, household_id: int, user_id: int) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id, cls.user_id == user_id
        ).first()

    @classmethod
    def find_by_household(cls, household_id: int) -> list[Self]:
        return cls.query.filter(cls.household_id == household_id).all()

    @classmethod
    def find_by_user(cls, user_id: int) -> list[Self]:
        return cls.query.filter(cls.user_id == user_id).all()
