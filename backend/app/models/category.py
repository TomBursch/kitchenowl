from __future__ import annotations
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin, DbModelAuthorizeMixin


class Category(db.Model, DbModelMixin, TimestampMixin, DbModelAuthorizeMixin):
    __tablename__ = 'category'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    default = db.Column(db.Boolean, default=False)
    ordering = db.Column(db.Integer, default=0)
    household_id = db.Column(db.Integer, db.ForeignKey(
        'household.id'), nullable=False)

    household = db.relationship("Household", uselist=False)
    items = db.relationship(
        'Item', back_populates='category')

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def all_by_ordering(cls, household_id: int):
        return cls.query.filter(cls.household_id == household_id).order_by(cls.ordering, cls.name).all()

    @classmethod
    def create_by_name(cls, household_id: int, name, default=False) -> Self:
        return cls(
            name=name,
            default=default,
            household_id=household_id,
        ).save()

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self:
        return cls.query.filter(cls.name == name, cls.household_id == household_id).first()

    @classmethod
    def find_by_id(cls, id: int) -> Self:
        return cls.query.filter(cls.id == id).first()

    def reorder(self, newIndex: int):
        cls = self.__class__
        self.ordering = newIndex

        l: list[cls] = cls.query.filter(cls.household_id == self.household_id).order_by(
            cls.ordering, cls.name).all()

        oldIndex = list(map(lambda x: x.id, l)).index(self.id)
        if oldIndex < 0:
            raise Exception()  # Something went wrong
        e = l.pop(oldIndex)

        l.insert(newIndex, e)

        for i, category in enumerate(l):
            category.ordering = i

        try:
            db.session.add_all(l)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e
