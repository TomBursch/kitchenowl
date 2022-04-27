from __future__ import annotations
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from app.helpers.db_set_type import DbSetType
from .item import Item
from .tag import Tag
from random import randint


class Recipe(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'recipe'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    description = db.Column(db.String())
    photo = db.Column(db.String())
    planned = db.Column(db.Boolean)
    planned_days = db.Column(DbSetType(), default=set())
    time = db.Column(db.Integer)
    source = db.Column(db.String())
    suggestion_score = db.Column(db.Integer, server_default='0')
    suggestion_rank = db.Column(db.Integer, server_default='0')

    recipe_history = db.relationship(
        "RecipeHistory", back_populates="recipe", cascade="all, delete-orphan")
    items = db.relationship(
        'RecipeItems', back_populates='recipe', cascade="all, delete-orphan")
    tags = db.relationship(
        'RecipeTags', back_populates='recipe', cascade="all, delete-orphan")

    def obj_to_dict(self):
        res = super().obj_to_dict()
        res['planned_days'] = list(self.planned_days)
        return res

    def obj_to_full_dict(self) -> dict:
        res = self.obj_to_dict()
        items = RecipeItems.query.filter(RecipeItems.recipe_id == self.id).join(
            RecipeItems.item).order_by(
            Item.name).all()
        res['items'] = [e.obj_to_item_dict() for e in items]
        tags = RecipeTags.query.filter(RecipeTags.recipe_id == self.id).join(
            RecipeTags.tag).order_by(
            Tag.name).all()
        res['tags'] = [e.obj_to_item_dict() for e in tags]
        return res

    def obj_to_export_dict(self) -> dict:
        items = RecipeItems.query.filter(RecipeItems.recipe_id == self.id).join(
            RecipeItems.item).order_by(
            Item.name).all()
        tags = RecipeTags.query.filter(RecipeTags.recipe_id == self.id).join(
            RecipeTags.tag).order_by(
            Tag.name).all()
        res = {
            "name": self.name,
            "description": self.description,
            "time": self.time,
            "source": self.source,
            "items": [{"name": e.item.name, "description": e.description, "optional": e.optional} for e in items],
            "tags": [e.tag.name for e in tags],
        }
        return res

    @classmethod
    def compute_suggestion_ranking(cls):
        # reset all suggestion ranks
        for r in cls.all():
            r.suggestion_rank = 0
        # get all recipes with positive suggestion_score
        recipes = cls.query.filter(  # noqa
            cls.suggestion_score != 0).all()
        # compute the initial sum of all suggestion_scores
        suggestion_sum = 0
        for r in recipes:
            suggestion_sum += r.suggestion_score
        # iteratively assign increasing suggestion rank to random recipes weighted by their score
        current_rank = 1
        while len(recipes) > 0:
            choose = randint(1, suggestion_sum)
            to_be_removed = -1
            for (i, r) in enumerate(recipes):
                choose -= r.suggestion_score
                if choose <= 0:
                    r.suggestion_rank = current_rank
                    current_rank += 1
                    suggestion_sum -= r.suggestion_score
                    to_be_removed = i
                    break
            recipes.pop(to_be_removed)
        db.session.commit()

    @classmethod
    def find_suggestions(cls):
        return cls.query.filter(cls.planned == False).filter(  # noqa
            cls.suggestion_rank > 0).order_by(cls.suggestion_rank).all()

    @classmethod
    def find_by_name(cls, name) -> Recipe:
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id) -> Recipe:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def search_name(cls, name):
        recipe_count = 12
        if '*' in name or '_' in name:
            looking_for = name.replace('_', '__')\
                .replace('*', '%')\
                .replace('?', '_')
        else:
            looking_for = '%{0}%'.format(name)
        return cls.query.filter(cls.name.ilike(looking_for)).limit(recipe_count).all()

    @classmethod
    def all_by_name_with_filter(cls, filter):
        sq = db.session.query(RecipeTags.recipe_id).join(RecipeTags.tag).filter(
            Tag.name.in_(filter)).subquery()
        return db.session.query(cls).filter(cls.id.in_(sq)).order_by(cls.name).all()


class RecipeItems(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'recipe_items'

    recipe_id = db.Column(db.Integer, db.ForeignKey(
        'recipe.id'), primary_key=True)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), primary_key=True)
    description = db.Column('description', db.String())
    optional = db.Column('optional', db.Boolean)

    item = db.relationship("Item", back_populates='recipes')
    recipe = db.relationship("Recipe", back_populates='items')

    def obj_to_item_dict(self):
        res = self.item.obj_to_dict()
        res['description'] = getattr(self, 'description')
        res['optional'] = getattr(self, 'optional')
        res['created_at'] = getattr(self, 'created_at')
        res['updated_at'] = getattr(self, 'updated_at')
        return res

    def obj_to_recipe_dict(self):
        res = self.recipe.obj_to_dict()
        res['items'] = [
            {
                'id': getattr(self, 'item_id'),
                'description': getattr(self, 'description'),
                'optional': getattr(self, 'optional'),
            }
        ]
        return res

    @classmethod
    def find_by_ids(cls, recipe_id, item_id):
        return cls.query.filter(cls.recipe_id == recipe_id, cls.item_id == item_id).first()


class RecipeTags(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'recipe_tags'

    recipe_id = db.Column(db.Integer, db.ForeignKey(
        'recipe.id'), primary_key=True)
    tag_id = db.Column(db.Integer, db.ForeignKey('tag.id'), primary_key=True)

    tag = db.relationship("Tag", back_populates='recipes')
    recipe = db.relationship("Recipe", back_populates='tags')

    def obj_to_item_dict(self):
        res = self.tag.obj_to_dict()
        res['created_at'] = getattr(self, 'created_at')
        res['updated_at'] = getattr(self, 'updated_at')
        return res

    @classmethod
    def find_by_ids(cls, recipe_id, tag_id):
        return cls.query.filter(cls.recipe_id == recipe_id, cls.tag_id == tag_id).first()
