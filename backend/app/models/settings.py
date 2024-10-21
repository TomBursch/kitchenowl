from typing import Self
from app import db
from app.helpers import DbModelMixin
from sqlalchemy.orm import Mapped


class Settings(db.Model , DbModelMixin):
    __tablename__ = "settings"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True, nullable=False)

    @classmethod
    def get(cls) -> Self:
        settings = cls.query.first()
        if not settings:
            settings = cls()
            settings.save()
        return settings
