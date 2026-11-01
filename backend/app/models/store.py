from typing import Any, Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, ItemStores
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Store(Model, DbModelAuthorizeMixin):
    __tablename__ = "store"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))

    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship(
            "Household",
            uselist=False,
        ),
    )
    items: Mapped[List["ItemStores"]] = cast(
        Mapped[List["ItemStores"]],
        db.relationship(
            "ItemStores",
            back_populates="store",
            cascade="all, delete-orphan",
        ),
    )

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = self.obj_to_dict()
        return res

    def merge(self, other: Self) -> None:
        if self.household_id != other.household_id:
            return

        from app.models import ItemStores

        for istore in ItemStores.query.filter(
            ItemStores.store_id == other.id,
            ItemStores.item_id.notin_(
                db.session.query(ItemStores.item_id)
                .filter(ItemStores.store_id == self.id)
                .subquery()
                .select()
            ),
        ).all():
            istore.store_id = self.id
            db.session.add(istore)

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
    def find_by_name(cls, household_id: int, name: str) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id, cls.name == name
        ).first()
