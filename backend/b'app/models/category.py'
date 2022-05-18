from __future__ import annotations
from app import db
from app.helpers import DbModelMixin, TimestampMixin


class Category(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'category'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    default = db.Column(db.Boolean, default=False)

    items = db.relationship(
        'Item', back_populates='category')

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def create_by_name(cls, name, default=False) -> Category:
        return cls(
            name=name,
            default=default,
        ).save()

    @classmethod
    def find_by_name(cls, name) -> Category:
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Category:
        return cls.query.filter(cls.id == id).first()
