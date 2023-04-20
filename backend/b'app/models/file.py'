from __future__ import annotations
from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin, DbModelAuthorizeMixin
from app.models.user import User


class File(db.Model, DbModelMixin, TimestampMixin, DbModelAuthorizeMixin):
    __tablename__ = 'file'

    filename = db.Column(db.String(), primary_key=True)
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'), primary_key=True)

    created_by_user = db.relationship("User", foreign_keys=[created_by], uselist=False)

    household = db.relationship("Household", uselist=False)
    recipe = db.relationship("Recipe", uselist=False)
    expense = db.relationship("Expense", uselist=False)
    profile_picture = db.relationship("User", foreign_keys=[User.photo], uselist=False)

    @classmethod
    def find(cls, filename: str) -> Self:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.filename == filename).first()

