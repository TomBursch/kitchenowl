from app import db
from app.helpers import DbModelMixin, TimestampMixin


class Tag(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'tag'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))

    recipes = db.relationship(
        'RecipeTags', back_populates='tag', cascade="all, delete-orphan")

    def obj_to_full_dict(self):
        res = super().obj_to_dict()
        return res

    @classmethod
    def create_by_name(cls, name):
        return cls(
            name=name,
        ).save()

    @classmethod
    def find_by_name(cls, name):
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id):
        return cls.query.filter(cls.id == id).first()
