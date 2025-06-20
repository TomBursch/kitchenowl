from typing import TYPE_CHECKING, Any, cast

from app import db
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import User, Recipe
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Report(Model):
    __tablename__ = "report"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    description: Mapped[str] = db.Column(db.String)
    created_by_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )

    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )
    recipe_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("recipe.id"), nullable=True
    )

    created_by: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship(
            "User",
            foreign_keys=[created_by_id],
            back_populates="created_reports",
        ),
    )

    user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship(
            "User",
            foreign_keys=[user_id],
            back_populates="reports",
        ),
    )
    recipe: Mapped["Recipe"] = cast(
        Mapped["Recipe"],
        db.relationship(
            "Recipe",
            back_populates="reports",
        ),
    )

    def obj_to_full_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = self.obj_to_dict(skip_columns, include_columns)
        if self.user:
            res["user"] = self.user.obj_to_dict()
        if self.recipe:
            res["recipe"] = self.recipe.obj_to_dict()
        if self.created_by:
            res["created_by"] = self.created_by.obj_to_dict()

        for column_name in skip_columns or []:
            if column_name in res:
                del res[column_name]
        return res
