from typing import Any, Self, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class LoyaltyCard(Model, DbModelAuthorizeMixin):
    __tablename__ = "loyalty_card"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128), nullable=False)
    barcode_type: Mapped[str | None] = db.Column(db.String(32))
    barcode_data: Mapped[str | None] = db.Column(db.String(256))
    description: Mapped[str | None] = db.Column(db.String(512))
    color: Mapped[int | None] = db.Column(db.Integer)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship(
            "Household",
            back_populates="loyaltyCards",
            uselist=False,
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        return self.obj_to_dict()

    @classmethod
    def find_by_id(cls, id: int) -> Self | None:
        return cls.query.filter(cls.id == id).first()

    @classmethod
    def find_by_household(cls, household_id: int) -> list[Self]:
        return cls.query.filter(cls.household_id == household_id).order_by(cls.name).all()

