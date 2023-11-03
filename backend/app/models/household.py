from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from app.helpers.db_list_type import DbListType


class Household(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "household"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    photo = db.Column(db.String(), db.ForeignKey("file.filename"))
    language = db.Column(db.String())
    planner_feature = db.Column(db.Boolean(), nullable=False, default=True)
    expenses_feature = db.Column(db.Boolean(), nullable=False, default=True)

    view_ordering = db.Column(DbListType(), default=list())

    items = db.relationship(
        "Item", back_populates="household", cascade="all, delete-orphan"
    )
    shoppinglists = db.relationship(
        "Shoppinglist", back_populates="household", cascade="all, delete-orphan"
    )
    categories = db.relationship(
        "Category", back_populates="household", cascade="all, delete-orphan"
    )
    recipes = db.relationship(
        "Recipe", back_populates="household", cascade="all, delete-orphan"
    )
    tags = db.relationship(
        "Tag", back_populates="household", cascade="all, delete-orphan"
    )
    expenses = db.relationship(
        "Expense", back_populates="household", cascade="all, delete-orphan"
    )
    expenseCategories = db.relationship(
        "ExpenseCategory", back_populates="household", cascade="all, delete-orphan"
    )
    member = db.relationship(
        "HouseholdMember", back_populates="household", cascade="all, delete-orphan"
    )
    photo_file = db.relationship("File", back_populates="household", uselist=False)

    def obj_to_dict(self) -> dict:
        res = super().obj_to_dict()
        res["member"] = [m.obj_to_user_dict() for m in getattr(self, "member")]
        res["default_shopping_list"] = self.shoppinglists[0].obj_to_dict()
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


class HouseholdMember(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "household_member"

    household_id = db.Column(
        db.Integer, db.ForeignKey("household.id"), primary_key=True
    )
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), primary_key=True)

    owner = db.Column(db.Boolean(), default=False, nullable=False)
    admin = db.Column(db.Boolean(), default=False, nullable=False)

    expense_balance = db.Column(db.Float(), default=0, nullable=False)

    household = db.relationship("Household", back_populates="member")
    user = db.relationship("User", back_populates="households")

    def obj_to_user_dict(self) -> dict:
        res = self.user.obj_to_dict()
        res["owner"] = getattr(self, "owner")
        res["admin"] = getattr(self, "admin")
        res["expense_balance"] = getattr(self, "expense_balance")
        return res

    def delete(self):
        if len(self.household.member) <= 1:
            self.household.delete()
        elif self.owner:
            newOwner = next(
                (m for m in self.household.member if m.admin and m != self),
                next((m for m in self.household.member if m != self)),
            )
            newOwner.admin = True
            newOwner.owner = True
            newOwner.save()
            super().delete()
        else:
            super().delete()

    @classmethod
    def find_by_ids(cls, household_id: int, user_id: int) -> Self:
        return cls.query.filter(
            cls.household_id == household_id, cls.user_id == user_id
        ).first()

    @classmethod
    def find_by_household(cls, household_id: int) -> list[Self]:
        return cls.query.filter(cls.household_id == household_id).all()

    @classmethod
    def find_by_user(cls, user_id: int) -> list[Self]:
        return cls.query.filter(cls.user_id == user_id).all()
