from __future__ import annotations
from typing import Self, TYPE_CHECKING, cast

from flask_jwt_extended import current_user
from app import db
from app.config import UPLOAD_FOLDER
from app.errors import ForbiddenRequest
from app.helpers import DbModelAuthorizeMixin
from app.models.user import User
import os
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, Recipe, Expense
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class File(Model, DbModelAuthorizeMixin):
    __tablename__ = "file"

    filename: Mapped[str] = db.Column(db.String(), primary_key=True)
    blur_hash: Mapped[str | None] = db.Column(db.String(length=40), nullable=True)
    created_by: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )

    created_by_user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship("User", foreign_keys=[created_by], uselist=False, init=False),
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"], db.relationship("Household", uselist=False, init=False)
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"], db.relationship("Recipe", uselist=False, init=False)
    )
    expense: Mapped["Expense"] = cast(
        Mapped["Expense"], db.relationship("Expense", uselist=False, init=False)
    )
    profile_picture: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship("User", foreign_keys=[User.photo], uselist=False, init=False),
    )

    def delete(self):
        """
        Delete this instance of model from db
        """
        os.remove(os.path.join(UPLOAD_FOLDER, self.filename))
        db.session.delete(self)
        db.session.commit()

    def isUnused(self) -> bool:
        return (
            not self.household
            and not self.recipe
            and not self.expense
            and not self.profile_picture
        )

    def checkAuthorized(self, requires_admin=False, household_id: int | None = None):
        if self.created_by and current_user and self.created_by == current_user.id:
            pass  # created by user can access his pictures
        elif self.profile_picture:
            pass  # profile pictures are public
        elif self.recipe:
            if not self.recipe.public:
                super().checkAuthorized(
                    household_id=self.recipe.household_id, requires_admin=requires_admin
                )
        elif self.household:
            super().checkAuthorized(
                household_id=self.household.id, requires_admin=requires_admin
            )
        elif self.expense:
            super().checkAuthorized(
                household_id=self.expense.household_id, requires_admin=requires_admin
            )
        else:
            raise ForbiddenRequest()

    @classmethod
    def find(cls, filename: str) -> Self | None:
        """
        Find the row with specified id
        """
        return cls.query.filter(cls.filename == filename).first()
