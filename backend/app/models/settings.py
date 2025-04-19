from typing import TYPE_CHECKING, Self
from app import db
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Settings(Model):
    __tablename__ = "settings"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True, nullable=False)

    @classmethod
    def get(cls) -> Self:
        settings = cls.query.first()
        if not settings:
            settings = cls()
            settings.save()
        return settings
