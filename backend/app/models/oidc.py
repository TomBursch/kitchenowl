from datetime import datetime, timedelta, timezone
from typing import Optional, Self, TYPE_CHECKING, cast

from app import db
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class OIDCLink(Model):
    __tablename__ = "oidc_link"

    sub: Mapped[str] = db.Column(db.String(256), primary_key=True)
    provider: Mapped[str] = db.Column(db.String(24), primary_key=True)
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False, index=True
    )

    user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship(
            "User",
            back_populates="oidc_links",
        ),
    )

    @classmethod
    def find_by_ids(cls, sub: str, provider: str) -> Self | None:
        return cls.query.filter(cls.sub == sub, cls.provider == provider).first()


class OIDCRequest(Model):
    __tablename__ = "oidc_request"

    state: Mapped[str] = db.Column(db.String(256), primary_key=True)
    provider: Mapped[str] = db.Column(db.String(24), primary_key=True)
    nonce: Mapped[str] = db.Column(db.String(256), nullable=False)
    redirect_uri: Mapped[str] = db.Column(db.String(256), nullable=False)
    user_id: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )

    user: Mapped[Optional["User"]] = cast(
        Mapped[Optional["User"]],
        db.relationship(
            "User",
            back_populates="oidc_link_requests",
        ),
    )

    @classmethod
    def find_by_state(cls, state: str) -> Self | None:
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
