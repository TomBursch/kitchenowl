from __future__ import annotations
from typing import Self
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

    @classmethod
    def get_column_names(cls) -> list[str]:
        return list(cls.__table__.columns.keys())

    @classmethod
    def find_by_id(cls, target_id: int) -> Self:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.id == target_id).first()

    @classmethod
    def delete_by_id(cls, target_id: int) -> bool:
        mc = cls.find_by_id(target_id)
        if mc:
            mc.delete()
            return True
        return False

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
    def all_from_household(cls, household_id: int) -> list[Self]:
        """
        Return all instances of model
        IMPORTANT: requires household_id column
        """
        return cls.query.filter(cls.household_id == household_id).order_by(cls.id).all()

    @classmethod
    def all_from_household_by_name(cls, household_id: int) -> list[Self]:
        """
        Return all instances of model
        IMPORTANT: requires household_id and name column
        """
        return cls.query.filter(cls.household_id == household_id).order_by(cls.name).all()

    @classmethod
    def count(cls) -> int:
        return cls.query.count()
