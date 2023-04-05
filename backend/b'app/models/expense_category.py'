from __future__ import annotations
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin, DbModelAuthorizeMixin


class ExpenseCategory(db.Model, DbModelMixin, TimestampMixin, DbModelAuthorizeMixin):
    __tablename__ = 'expense_category'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    color = db.Column(db.Integer)
    household_id = db.Column(db.Integer, db.ForeignKey(
        'household.id'), nullable=False)

    household = db.relationship("Household", uselist=False)
    expenses = db.relationship(
        'Expense', back_populates='category')

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def find_by_name(cls, name: str, houshold_id: int) -> Self:
        return cls.query.filter(cls.name == name, cls.household_id == houshold_id).first()

    @classmethod
    def find_by_id(cls, id) -> Self:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def delete_by_name(cls, name: str, household_id: int):
        mc = cls.find_by_name(name, household_id)
        if mc:
            mc.delete()
