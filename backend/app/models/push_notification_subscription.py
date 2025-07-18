from typing import Any, Self, TYPE_CHECKING, cast

from app import db
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Token
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class PushNotificationSubscription(Model):
    __tablename__ = "push_notification_subscription"

    endpoint: Mapped[str] = db.Column(db.String(), primary_key=True)
    pubkey: Mapped[str] = db.Column(db.String())
    auth: Mapped[str] = db.Column(db.String())

    # Should never be an access token
    created_by_token_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("token.jti"), nullable=False
    )
    created_by_token: Mapped["Token"] = cast(
        Mapped["Token"],
        db.relationship("Token"),
    )

    def toSubsciptionInfo(self) -> dict[str, Any]:
        return {
            "endpoint": self.endpoint,
            "keys": {
                "p256dh": self.pubkey,
                "auth": self.auth,
            },
        }

    @classmethod
    def find_by_user(cls, user_id: int) -> list[Self] | None:
        return cls.query.filter(cls.created_by_token.user_id == user_id).all()
