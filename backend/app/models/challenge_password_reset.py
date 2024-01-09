from __future__ import annotations
from datetime import datetime, timedelta
import hashlib
from typing import Self
import uuid
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from app.models.user import User


class ChallengePasswordReset(db.Model, DbModelMixin, TimestampMixin):
    challenge_hash = db.Column(db.String(256), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    user = db.relationship("User")

    @classmethod
    def find_by_challenge(cls, challenge: str) -> Self:
        filter_before = datetime.utcnow() - timedelta(hours=3)
        return cls.query.filter(
            cls.challenge_hash == hashlib.sha256(bytes(challenge, "utf-8")).hexdigest(),
            cls.created_at >= filter_before,
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

    @classmethod
    def delete_expired(cls):
        filter_before = datetime.utcnow() - timedelta(hours=3)
        db.session.query(cls).filter(cls.created_at <= filter_before).delete()
        db.session.commit()
