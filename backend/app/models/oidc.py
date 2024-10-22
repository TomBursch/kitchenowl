from datetime import datetime, timedelta, timezone
from typing import Self, TYPE_CHECKING

from app import db
from app.helpers import DbModelMixin
from sqlalchemy.orm import Mapped

if TYPE_CHECKING:
    from app.models import *


class OIDCLink(db.Model, DbModelMixin):
    __tablename__ = "oidc_link"

    sub: Mapped[str] = db.Column(db.String(256), primary_key=True)
    provider: Mapped[str] = db.Column(db.String(24), primary_key=True)
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False, index=True
    )

    user: Mapped["User"] = db.relationship("User", back_populates="oidc_links")

    @classmethod
    def find_by_ids(cls, sub: str, provider: str) -> Self:
        return cls.query.filter(cls.sub == sub, cls.provider == provider).first()


class OIDCRequest(db.Model, DbModelMixin):
    __tablename__ = "oidc_request"

    state: Mapped[str] = db.Column(db.String(256), primary_key=True)
    provider: Mapped[str] = db.Column(db.String(24), primary_key=True)
    nonce: Mapped[str] = db.Column(db.String(256), nullable=False)
    redirect_uri: Mapped[str] = db.Column(db.String(256), nullable=False)
    user_id: Mapped[int] = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=True)

    user: Mapped["User"] = db.relationship("User", back_populates="oidc_link_requests")

    @classmethod
    def find_by_state(cls, state: str) -> Self:
        filter_before = datetime.now(timezone.utc) - timedelta(minutes=7)
        return cls.query.filter(
            cls.state == state,
            cls.created_at >= filter_before,
        ).first()

    @classmethod
    def delete_expired(cls):
        filter_before = datetime.now(timezone.utc) - timedelta(minutes=7)
        db.session.query(cls).filter(cls.created_at <= filter_before).delete()
        db.session.commit()
