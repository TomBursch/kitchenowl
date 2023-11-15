from datetime import datetime, timedelta
from typing import Self

from app import db
from app.helpers import DbModelMixin, TimestampMixin


class OIDCLink(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "oidc_link"

    sub = db.Column(db.String(256), primary_key=True)
    provider = db.Column(db.String(24), primary_key=True)
    user_id = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False, index=True
    )

    user = db.relationship("User", back_populates="oidc_links")

    @classmethod
    def find_by_ids(cls, sub: str, provider: str) -> Self:
        return cls.query.filter(cls.sub == sub, cls.provider == provider).first()


class OIDCRequest(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "oidc_request"

    state = db.Column(db.String(256), primary_key=True)
    provider = db.Column(db.String(24), primary_key=True)
    nonce = db.Column(db.String(256), nullable=False)
    redirect_uri = db.Column(db.String(256), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=True)

    user = db.relationship("User", back_populates="oidc_link_requests")

    @classmethod
    def find_by_state(cls, state: str) -> Self:
        filter_before = datetime.utcnow() - timedelta(minutes=7)
        return cls.query.filter(
            cls.state == state,
            cls.created_at >= filter_before,
        ).first()

    @classmethod
    def delete_expired(cls):
        filter_before = datetime.utcnow() - timedelta(minutes=7)
        db.session.query(cls).filter(cls.created_at <= filter_before).delete()
        db.session.commit()
