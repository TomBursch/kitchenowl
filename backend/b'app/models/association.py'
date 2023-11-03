from typing import Self
from app import db
from app.helpers import DbModelMixin, TimestampMixin


class Association(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "association"

    id = db.Column(db.Integer, primary_key=True)

    antecedent_id = db.Column(db.Integer, db.ForeignKey("item.id"))
    consequent_id = db.Column(db.Integer, db.ForeignKey("item.id"))
    support = db.Column(db.Float)
    confidence = db.Column(db.Float)
    lift = db.Column(db.Float)

    antecedent = db.relationship(
        "Item",
        uselist=False,
        foreign_keys=[antecedent_id],
        back_populates="antecedents",
    )
    consequent = db.relationship(
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
