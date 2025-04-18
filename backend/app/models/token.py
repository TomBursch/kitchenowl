from __future__ import annotations
from datetime import datetime, timezone
from typing import Optional, Self, Tuple, List, TYPE_CHECKING, cast

from app import db
from app.config import JWT_REFRESH_TOKEN_EXPIRES, JWT_ACCESS_TOKEN_EXPIRES
from app.errors import UnauthorizedRequest, getClientIp
from flask_jwt_extended import create_access_token, create_refresh_token, get_jti
from app.models.user import User
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Token(Model):
    __tablename__ = "token"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    jti: Mapped[str] = db.Column(db.String(36), nullable=False, index=True)
    type: Mapped[str] = db.Column(db.String(16), nullable=False)
    name: Mapped[str] = db.Column(db.String(), nullable=False)
    last_used_at: Mapped[datetime] = db.Column(db.DateTime)
    refresh_token_id: Mapped[Optional[int]] = db.Column(
        db.Integer, db.ForeignKey("token.id"), nullable=True
    )
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False
    )

    created_tokens: Mapped[List["Token"]] = cast(
        Mapped[List["Token"]],
        db.relationship(
            "Token",
            back_populates="refresh_token",
            cascade="all, delete-orphan",
            init=False,
        ),
    )
    refresh_token: Mapped["Token"] = cast(
        Mapped["Token"], db.relationship("Token", remote_side=[id], init=False)
    )
    user: Mapped["User"] = cast(
        Mapped["User"], db.relationship("User", lazy="selectin", init=False)
    )

    def obj_to_dict(self, skip_columns=None, include_columns=None) -> dict:
        if skip_columns:
            skip_columns = skip_columns + ["jti"]
        else:
            skip_columns = ["jti"]
        return super().obj_to_dict(
            skip_columns=skip_columns, include_columns=include_columns
        )

    @classmethod
    def find_by_jti(cls, jti: str) -> Self | None:
        return cls.query.filter(cls.jti == jti).first()

    @classmethod
    def delete_expired_refresh(cls):
        filter_before = datetime.now(timezone.utc) - JWT_REFRESH_TOKEN_EXPIRES

        # Delete expired regular refresh tokens with no children
        for token in (
            db.session.query(cls)
            .filter(
                cls.created_at <= filter_before,
                cls.type == "refresh",
                ~cls.created_tokens.any(),
            )
            .all()
        ):
            token.delete_token_familiy(commit=False)

        # Delete expired invalidated refresh tokens
        db.session.query(cls).filter(
            cls.created_at <= filter_before, cls.type == "revoked_refresh"
        ).delete()

        db.session.commit()

    @classmethod
    def delete_expired_access(cls):
        filter_before = datetime.now(timezone.utc) - JWT_ACCESS_TOKEN_EXPIRES
        db.session.query(cls).filter(
            cls.created_at <= filter_before, cls.type == "access"
        ).delete()
        db.session.commit()

    # Delete oldest refresh token -> log out device
    # Used e.g. when a refresh token is used twice
    def delete_token_familiy(self, commit=True):
        if self.type not in ["refresh", "invalidated_refresh", "revoked_refresh"]:
            return

        token = self
        while token:
            if token.refresh_token:
                token = token.refresh_token
            else:
                db.session.delete(token)
                token = None
        if commit:
            db.session.commit()

    def has_created_refresh_token(self) -> bool:
        return (
            db.session.query(Token)
            .filter(Token.refresh_token_id == self.id, Token.type == "refresh")
            .count()
            > 0
        )

    def delete_created_access_tokens(self, commit=True):
        if self.type != "refresh":
            return
        Token.query.filter(
            Token.refresh_token_id == self.id, Token.type == "access"
        ).delete()
        if commit:
            db.session.commit()

    @classmethod
    def create_access_token(
        cls, user: User, refreshTokenModel: Self
    ) -> Tuple[str, Self]:
        accesssToken = create_access_token(identity=user)
        model = cls()
        model.jti = cast(str, get_jti(accesssToken))
        model.type = "access"
        model.name = refreshTokenModel.name
        model.user = user
        model.refresh_token = refreshTokenModel
        model.save()
        return accesssToken, model

    @classmethod
    def create_refresh_token(
        cls, user: User, device: str | None = None, oldRefreshToken: Self | None = None
    ) -> Tuple[str, Self]:
        assert device or oldRefreshToken
        if oldRefreshToken and oldRefreshToken.type != "refresh":
            oldRefreshToken.delete_token_familiy()
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} reused the same refresh token, logging out user".format(
                    getClientIp()
                )
            )

        # Check if this refresh token has already been used to create another refresh token
        if oldRefreshToken and oldRefreshToken.has_created_refresh_token():
            for newer_token in Token.query.filter(
                Token.refresh_token_id == oldRefreshToken.id, Token.type == "refresh"
            ).all():
                newer_access_used = (
                    db.session.query(Token)
                    .filter(
                        Token.refresh_token_id == newer_token.id,
                        Token.type == "access",
                        Token.last_used_at != None,
                    )
                    .count()
                    > 0
                )

                if newer_token.last_used_at is not None or newer_access_used:
                    # The newer tokens have been used, this is a reuse attack
                    oldRefreshToken.delete_token_familiy()
                    raise UnauthorizedRequest(
                        message="Unauthorized: IP {} reused the same refresh token, logging out user".format(
                            getClientIp()
                        )
                    )
                else:
                    # Only invalidate the unused parallel refresh token chain
                    Token.query.filter(
                        Token.refresh_token_id == newer_token.id
                    ).delete()
                    newer_token.type = "revoked_refresh"
                    db.session.add(newer_token)

        refreshToken = create_refresh_token(identity=user)
        model = cls()
        model.jti = cast(str, get_jti(refreshToken))
        model.type = "refresh"
        model.name = device or (oldRefreshToken.name if oldRefreshToken else "Unknown")
        model.user = user
        if oldRefreshToken:
            oldRefreshToken.delete_created_access_tokens(commit=False)
            model.refresh_token = oldRefreshToken
        model.save()
        return refreshToken, model

    @classmethod
    def create_longlived_token(cls, user: User, device: str) -> Tuple[str, Self]:
        accesssToken = create_access_token(identity=user, expires_delta=False)
        model = cls()
        model.jti = cast(str, get_jti(accesssToken))
        model.type = "llt"
        model.name = device
        model.user = user
        model.save()
        return accesssToken, model
