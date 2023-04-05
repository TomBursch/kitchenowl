from datetime import datetime
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from .shoppinglist import ShoppinglistItems
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
    shoppinglist = db.relationship("Shoppinglist", uselist=False, back_populates="history")

    status = db.Column(db.Enum(Status))
    description = db.Column('description', db.String())

    @classmethod
    def create_added_without_save(cls, shoppinglist, item, description='') -> Self:
        return cls(
            shoppinglist_id=shoppinglist.id,
            item_id=item.id,
            status=Status.ADDED,
            description=description
        )

    @classmethod
    def create_added(cls, shoppinglist, item, description='') -> Self:
        return cls.create_added_without_save(shoppinglist, item, description).save()

    @classmethod
    def create_dropped(cls, shoppinglist, item, description='', created_at=None) -> Self:
        return cls(
            shoppinglist_id=shoppinglist.id,
            item_id=item.id,
            status=Status.DROPPED,
            description=description,
            created_at=created_at or datetime.utcnow
        ).save()

    def obj_to_item_dict(self) -> dict:
        res = self.item.obj_to_dict()
        res['timestamp'] = getattr(self, 'created_at')
        return res

    @classmethod
    def find_added_by_shoppinglist_id(cls, shoppinglist_id: int) -> list[Self]:
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id, cls.status == Status.ADDED).all()

    @classmethod
    def find_dropped_by_shoppinglist_id(cls, shoppinglist_id: int) -> list[Self]:
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id, cls.status == Status.DROPPED).all()

    @classmethod
    def find_by_shoppinglist_id(cls, shoppinglist_id: int) -> list[Self]:
        return cls.query.filter(cls.shoppinglist_id == shoppinglist_id).all()

    @classmethod
    def find_all(cls) -> list[Self]:
        return cls.query.all()

    @classmethod
    def get_recent(cls, shoppinglist_id: int) -> list[Self]:
        sq = db.session.query(
            ShoppinglistItems.item_id).subquery().select()
        sq2 = db.session.query(func.max(cls.id)).filter(cls.status == Status.DROPPED).filter(
            cls.item_id.notin_(sq)).group_by(cls.item_id).join(cls.item).subquery().select()
        return cls.query.filter(
            cls.shoppinglist_id == shoppinglist_id).filter(cls.id.in_(sq2)).order_by(cls.id.desc()).limit(9)
