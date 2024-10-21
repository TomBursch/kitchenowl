from typing import Self, List
from app import db
from app.helpers import DbModelMixin, DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped


class Tag(db.Model , DbModelMixin, DbModelAuthorizeMixin):
    __tablename__ = "tag"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))

    household_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("household.id"), nullable=False)

    household: Mapped["Household"] = db.relationship("Household", uselist=False)
    recipes: Mapped[List["RecipeTags"]] = db.relationship(
        "RecipeTags", back_populates="tag", cascade="all, delete-orphan"
    )

    def obj_to_full_dict(self) -> dict:
        res = super().obj_to_dict()
        return res

    def merge(self, other: Self) -> None:
        if self.household_id != other.household_id:
            return

        from app.models import RecipeTags

        for rectag in RecipeTags.query.filter(
            RecipeTags.tag_id == other.id,
            RecipeTags.recipe_id.notin_(
                db.session.query(RecipeTags.recipe_id)
                .filter(RecipeTags.tag_id == self.id)
                .subquery()
                .select()
            ),
        ).all():
            rectag.tag_id = self.id
            db.session.add(rectag)

        try:
            db.session.commit()
            other.delete()
        except Exception as e:
            db.session.rollback()
            raise e

    @classmethod
    def create_by_name(cls, household_id: int, name: str) -> Self:
        return cls(
            name=name,
            household_id=household_id,
        ).save()

    @classmethod
    def find_by_name(cls, household_id: int, name: str) -> Self:
        return cls.query.filter(
            cls.household_id == household_id, cls.name == name
        ).first()

    @classmethod
    def find_by_id(cls, id: int) -> Self:
        return cls.query.filter(cls.id == id).first()
