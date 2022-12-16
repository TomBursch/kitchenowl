from __future__ import annotations
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from app.models.category import Category


class Item(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'item'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), unique=True)
    category_id = db.Column(db.Integer, db.ForeignKey('category.id'))
    default = db.Column(db.Boolean, default=False)

    category = db.relationship("Category")

    recipes = db.relationship(
        'RecipeItems', back_populates='item', cascade="all, delete-orphan")
    shoppinglists = db.relationship(
        'ShoppinglistItems', back_populates='item', cascade="all, delete-orphan")

    # determines order of items in the shoppinglist
    ordering = db.Column(db.Integer, server_default='0')
    # frequency of item, used for item suggestions
    support = db.Column(db.Float, server_default='0.0')

    history = db.relationship(
        "History", back_populates="item", cascade="all, delete-orphan")
    antecedents = db.relationship(
        "Association", back_populates="antecedent", foreign_keys='Association.antecedent_id')
    consequents = db.relationship(
        "Association", back_populates="consequent", foreign_keys='Association.consequent_id')

    def obj_to_dict(self) -> dict:
        res = super().obj_to_dict()
        if self.category_id:
            category = Category.find_by_id(self.category_id)
            res['category'] = category.obj_to_dict()
        return res

    def obj_to_export_dict(self) -> dict:
        res = {
            "name": self.name,
        }
        if self.category:
            res["category"] = self.category.name
        return res

    @classmethod
    def create_by_name(cls, name: str, default=False) -> Self:
        return cls(
            name=name.strip(),
            default=default,
        ).save()

    @classmethod
    def allByName(cls) -> list[Self]:
        """
        Return all instances of Item ordered by name
        """
        return cls.query.order_by(cls.name).all()

    @classmethod
    def find_by_name(cls, name: str) -> Self:
        name = name.strip()
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Self:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def search_name(cls, name: str) -> list[Self]:
        item_count = 11
        found = []

        # name is a regex
        if '*' in name or '?' in name or '%' in name or '_' in name:
            looking_for = name.replace('*', '%').replace('?', '_')
            found = cls.query.filter(cls.name.ilike(looking_for)).order_by(
                cls.support.desc()).limit(item_count).all()
            return found

        # name is no regex
        starts_with = '{0}%'.format(name)
        contains = '%{0}%'.format(name)
        one_error = []
        for index in range(len(name)):
            name_one_error = name[:index]+'_'+name[index+1:]
            one_error.append('%{0}%'.format(name_one_error))

        for looking_for in [starts_with, contains] + one_error:
            res = cls.query.filter(cls.name.ilike(looking_for)).order_by(
                cls.support.desc(), cls.name).all()
            for r in res:
                if r not in found:
                    found.append(r)
                    item_count -= 1
                    if item_count <= 0:
                        return found
        return found
