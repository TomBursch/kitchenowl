from __future__ import annotations
from typing import Self
from app import db
from app.config import UPLOAD_FOLDER
from app.helpers import DbModelMixin, TimestampMixin, DbModelAuthorizeMixin
from app.models.user import User
import os


class File(db.Model, DbModelMixin, TimestampMixin, DbModelAuthorizeMixin):
    __tablename__ = 'file'

    filename = db.Column(db.String(), primary_key=True)
    blur_hash = db.Column(db.String(length=40), nullable=True)
    created_by = db.Column(db.Integer, db.ForeignKey(
        'user.id'), nullable=True)

    created_by_user = db.relationship(
        "User", foreign_keys=[created_by], uselist=False)

    household = db.relationship("Household", uselist=False)
    recipe = db.relationship("Recipe", uselist=False)
    expense = db.relationship("Expense", uselist=False)
    profile_picture = db.relationship(
        "User", foreign_keys=[User.photo], uselist=False)

    def delete(self):
        """
        Delete this instance of model from db
        """
        os.remove(os.path.join(UPLOAD_FOLDER, self.filename))
        db.session.delete(self)
        db.session.commit()

    def isUnused(self) -> bool:
        return not self.household and not self.recipe and not self.expense and not self.profile_picture

    @classmethod
    def find(cls, filename: str) -> Self:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.filename == filename).first()
