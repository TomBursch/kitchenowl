from __future__ import annotations
from typing import Self
from sqlalchemy import asc, desc
from app import db


class DbModelMixin(object):

    def save(self) -> Self:
        """
        Persist changes to current instance in db
        """
        try:
            db.session.add(self)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e

        return self

    def assign(self, **kwargs) -> Self:
        """
        Update an entry
        """
        for k, v in kwargs.items():
            setattr(self, k, v)

        return self

    def assign_columns(self, args: dict):
        model_columns = list(self.__class__.__table__.columns.keys())
        for k, v in args.items():
            if k in model_columns:
                setattr(self, k, v)

        return self

    def update(self, details: dict):
        model_columns = list(self.__class__.__table__.columns.keys())
        for k, v in details.items():
            if k in model_columns and (v or v == ''):
                setattr(self, k, v)
        self.save()

    def update_attr(self, key: str, value):
        model_columns = list(self.__class__.__table__.columns.keys())
        if key in model_columns:
            setattr(self, key, value)
            self.save()

    @classmethod
    def get_column_names(cls) -> list[str]:
        return list(cls.__table__.columns.keys())

    @classmethod
    def bulk_save(cls, records):
        if not records:
            return

        try:
            db.session.bulk_save_objects(records)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e

    @classmethod
    def bulk_delete(cls, query):
        if not query.all():
            return

        try:
            query.delete()
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e

    def delete(self):
        """
        Delete this instance of model from db
        """
        db.session.delete(self)
        db.session.commit()

    def obj_to_dict(self, skip_columns: list[str] = None, include_columns: list[str] = None) -> dict:
        d = {}
        for column in self.__table__.columns:
            d[column.name] = getattr(self, column.name)

        for column_name in skip_columns or []:
            del d[column_name]

        for column in self.__table__.columns:
            if not include_columns:
                break

            if column.name in d and column.name not in include_columns:
                del d[column.name]

        return d

    def clone(self, overrides) -> Self:
        new_self = self.__class__()
        new_self.assign_columns(self.obj_to_dict())

        if overrides:
            for k, v in overrides.items():
                setattr(new_self, k, v)

        return new_self

    @classmethod
    def find_by_id(cls, target_id: int) -> Self:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.id == target_id).first()

    @classmethod
    def find_all_by_id(cls, target_id: int) -> list[Self]:
        """
        Find all the rows with specified id
        """
        return cls.query.filter(cls.id == target_id).all()

    @classmethod
    def find_all_by_ids(cls, target_ids: list[int]) -> list[Self]:
        """
        Find all the rows with specified id
        """
        return cls.query.filter(cls.id.in_(target_ids)).all()

    @classmethod
    def delete_by_id(cls, target_id: int):
        mc = cls.find_by_id(target_id)
        if mc:
            mc.delete()

    @classmethod
    def all(cls) -> list[Self]:
        """
        Return all instances of model
        """
        return cls.query.order_by(cls.id).all()

    @classmethod
    def all_by_name(cls) -> list[Self]:
        """
        Return all instances of model ordered by name
        IMPORTANT: requires name column
        """
        return cls.query.order_by(cls.name).all()

    @classmethod
    def first(cls) -> Self:
        """
        Returns the first entry of database
        """
        entities = cls.query.order_by(asc(cls.id)).limit(1).all()
        if len(entities) > 0:
            return entities[0]

        return None

    @classmethod
    def last(cls) -> Self:
        """
        Return the last entry of table in database
        """
        entities = cls.query.order_by(desc(cls.id)).limit(1).all()
        if len(entities) > 0:
            return entities[0]

        return None

    @classmethod
    def count(cls) -> int:
        return cls.query.count()
