from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin, DbModelAuthorizeMixin


class Tag(db.Model, DbModelMixin, TimestampMixin, DbModelAuthorizeMixin):
    __tablename__ = 'tag'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))

    household_id = db.Column(db.Integer, db.ForeignKey(
        'household.id'), nullable=False)

    household = db.relationship("Household", uselist=False)
    recipes = db.relationship('RecipeTags', back_populates='tag')

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    @classmethod
    def create_by_name(cls, household_id: int, name: str) -> Self:
        return cls(
            name=name,
            household_id=household_id,
        ).save()

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self:
        return cls.query.filter(cls.household_id == household_id, cls.name == name).first()

    @classmethod
    def find_by_id(cls, id: int) -> Self:
        return cls.query.filter(cls.id == id).first()
