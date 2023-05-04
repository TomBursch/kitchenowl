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

    def obj_to_export_dict(self) -> dict:
        return {
            'name': self.name,
            'color': self.color,
        }

    @classmethod
    def find_by_name(cls, houshold_id: int, name: str) -> Self:
        return cls.query.filter(cls.name == name, cls.household_id == houshold_id).first()

    @classmethod
    def find_by_id(cls, id: int) -> Self:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def delete_by_name(cls, household_id: int, name: str):
        mc = cls.find_by_name(household_id, name)
        if mc:
            mc.delete()
