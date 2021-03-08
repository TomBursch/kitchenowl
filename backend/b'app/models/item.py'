from app import db
from app.helpers import DbModelMixin, TimestampMixin

class Item(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'item'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), unique=True)

    recipes = db.relationship('RecipeItems', back_populates='item', cascade="all, delete-orphan")

    @classmethod
    def create_by_name(cls, name):
        return cls(
            name=name,
        ).save()

    @classmethod
    def find_by_name(cls, name):
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def search_name(cls, name):
        if '*' in name or '_' in name:
            looking_for = name.replace('_', '__')\
                .replace('*', '%')\
                .replace('?', '_')
        else:
            looking_for = '%{0}%'.format(name)
        return cls.query.filter(cls.name.ilike(looking_for)).limit(10)
