from app import db
from app.helpers import DbModelMixin, TimestampMixin
from .item import Item
from .shoppinglist import Shoppinglist, ShoppinglistItems
from sqlalchemy import func

import enum


class Status(enum.Enum):
    ADDED = 1
    DROPPED = -1


class History(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'history'

    id = db.Column(db.Integer, primary_key=True)

    shoppinglist_id = db.Column(db.Integer, db.ForeignKey(
        'shoppinglist.id'))
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'))

    item = db.relationship("Item", uselist=False, back_populates="history")

    status = db.Column(db.Enum(Status))

    @classmethod
    def create_added(cls, shoppinglist, item):
        return cls(
            shoppinglist_id=shoppinglist.id,
            item_id=item.id,
            status=Status.ADDED
        ).save()

    @classmethod
    def create_dropped(cls, shoppinglist, item):
        return cls(
            shoppinglist_id=shoppinglist.id,
            item_id=item.id,
            status=Status.DROPPED
        ).save()

    def obj_to_item_dict(self):
        res = self.item.obj_to_dict()
        res['timestamp'] = getattr(self, 'created_at')
        return res

    @classmethod
    def find_added_by_shoppinglist_id(cls, shoppinglist_id):
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id, cls.status == Status.ADDED).all()

    @classmethod
    def find_dropped_by_shoppinglist_id(cls, shoppinglist_id):
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id, cls.status == Status.DROPPED).all()

    @classmethod
    def find_by_shoppinglist_id(cls, shoppinglist_id):
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id).all()

    @classmethod
    def find_all(cls):
        return cls.query.all()

    @classmethod
    def get_recent(cls, shoppinglist_id):
        sq = db.session.query(ShoppinglistItems.item_id).filter(
            ShoppinglistItems.shoppinglist_id == shoppinglist_id).subquery().select(ShoppinglistItems.item_id)
        sq2 = db.session.query(func.max(cls.id)).filter(cls.status == Status.DROPPED).filter(
            cls.item_id.notin_(sq)).group_by(cls.item_id).join(cls.item).subquery().select(cls.id)
        return cls.query.filter(cls.id.in_(sq2)).order_by(cls.id.desc()).limit(9)
