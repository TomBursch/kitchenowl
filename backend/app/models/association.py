from typing import Self, TYPE_CHECKING
from app import db
from app.helpers import DbModelMixin
from sqlalchemy.orm import Mapped

if TYPE_CHECKING:
    from app.models import *


class Association(db.Model, DbModelMixin):
    __tablename__ = "association"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)

    antecedent_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("item.id"))
    consequent_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("item.id"))
    support: Mapped[float] = db.Column(db.Float)
    confidence: Mapped[float] = db.Column(db.Float)
    lift: Mapped[float] = db.Column(db.Float)

    antecedent: Mapped["Item"] = db.relationship(
        "Item",
        uselist=False,
        foreign_keys=[antecedent_id],
        back_populates="antecedents",
    )
    consequent: Mapped["Item"] = db.relationship(
        "Item",
        uselist=False,
        foreign_keys=[consequent_id],
        back_populates="consequents",
    )

    @classmethod
    def create(cls, antecedent_id, consequent_id, support, confidence, lift):
        return cls(
            antecedent_id=antecedent_id,
            consequent_id=consequent_id,
            support=support,
            confidence=confidence,
            lift=lift,
        ).save()

    @classmethod
    def find_by_antecedent(cls, antecedent_id):
        return cls.query.filter(cls.antecedent_id == antecedent_id).order_by(
            cls.lift.desc()
        )

    @classmethod
    def find_all(cls) -> list[Self]:
        return cls.query.all()

    @classmethod
    def delete_all(cls):
        cls.query.delete()
        db.session.commit()
