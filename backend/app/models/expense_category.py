from __future__ import annotations
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin


class ExpenseCategory(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'expense_category'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    color = db.Column(db.Integer)

    expenses = db.relationship(
        'Expense', back_populates='category')

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def find_by_name(cls, name) -> Self:
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Self:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def delete_by_name(cls, name):
        mc = cls.find_by_name(name)
        if mc:
            mc.delete()
