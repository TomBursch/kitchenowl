from dataclasses import field
from typing import TYPE_CHECKING, Any, Self
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import MetaData
from sqlalchemy.orm import Query

from app.helpers.db_model_timestamp_mixin import DbModelTimestampMixin


class DbModelBase(DeclarativeBase, DbModelTimestampMixin):
    metadata = MetaData(
        naming_convention={
            "ix": "ix_%(column_0_label)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
            "pk": "pk_%(table_name)s",
        }
    )

    if TYPE_CHECKING:
        query: Query[Self] = field(repr=False, init=False, compare=False)

    def save(self) -> Self:
        from ..config import db

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
        from ..config import db

        """
        Delete this instance of model from db
        """
        db.session.delete(self)
        db.session.commit()

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
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
    def find_by_id(cls, id: int) -> Self | None:
        """
        Find the row with specified id
        """
        assert hasattr(cls, "id")
        return cls.query.filter(cls.id == id).first()

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
        assert hasattr(cls, "id")
        return cls.query.order_by(cls.id).all()

    @classmethod
    def all_by_name(cls) -> list[Self]:
        """
        Return all instances of model ordered by name
        IMPORTANT: requires name column
        """
        assert hasattr(cls, "name")
        return cls.query.order_by(cls.name).all()

    @classmethod
    def all_from_household(cls, household_id: int) -> list[Self]:
        """
        Return all instances of model
        IMPORTANT: requires household_id column
        """
        assert hasattr(cls, "household_id")
        return cls.query.filter(cls.household_id == household_id).order_by(cls.id).all()

    @classmethod
    def all_from_household_by_name(cls, household_id: int) -> list[Self]:
        """
        Return all instances of model
        IMPORTANT: requires household_id and name column
        """
        assert hasattr(cls, "household_id") and hasattr(cls, "name")
        return (
            cls.query.filter(cls.household_id == household_id).order_by(cls.name).all()
        )

    @classmethod
    def count(cls) -> int:
        return cls.query.count()
