from __future__ import annotations
import hashlib
from typing import Self, TYPE_CHECKING, cast
import uuid
from app import db
from app.models.user import User
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class ChallengeMailVerify(Model):
    challenge_hash: Mapped[str] = db.Column(db.String(256), primary_key=True)
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False
    )

    user: Mapped["User"] = cast(Mapped["User"], db.relationship("User", init=False))

    @classmethod
    def find_by_challenge(cls, challenge: str) -> Self | None:
        return cls.query.filter(
            cls.challenge_hash == hashlib.sha256(bytes(challenge, "utf-8")).hexdigest()
        ).first()

    @classmethod
    def create_challenge(cls, user: User) -> str:
        challenge = uuid.uuid4().hex
        cls(
            challenge_hash=hashlib.sha256(bytes(challenge, "utf-8")).hexdigest(),
            user_id=user.id,
        ).save()
        return challenge

    @classmethod
    def delete_by_user(cls, user: User):
        cls.query.filter(cls.user_id == user.id).delete()
        db.session.commit()
