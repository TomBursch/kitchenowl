from __future__ import annotations
from datetime import datetime
from typing import Self, Tuple

from flask import request
from app import db
from app.config import JWT_REFRESH_TOKEN_EXPIRES, JWT_ACCESS_TOKEN_EXPIRES
from app.errors import UnauthorizedRequest
from app.helpers import DbModelMixin, TimestampMixin
from flask_jwt_extended import create_access_token, create_refresh_token, get_jti
from app.models.user import User


class Token(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'token'

    id = db.Column(db.Integer, primary_key=True)
    jti = db.Column(db.String(36), nullable=False, index=True)
    type = db.Column(db.String(16), nullable=False)
    name = db.Column(db.String(), nullable=False)
    last_used_at = db.Column(db.DateTime)
    refresh_token_id = db.Column(
        db.Integer, db.ForeignKey('token.id'), nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

    created_tokens = db.relationship(
        "Token", back_populates='refresh_token', cascade="all, delete-orphan")
    refresh_token = db.relationship("Token", remote_side=[id])
    user = db.relationship("User")

    def obj_to_dict(self, skip_columns=None, include_columns=None) -> dict:
        if skip_columns:
            skip_columns = skip_columns + ['jti']
        else:
            skip_columns = ['jti']
        return super().obj_to_dict(skip_columns=skip_columns, include_columns=include_columns)

    @classmethod
    def find_by_jti(cls, jti: str) -> Self:
        return cls.query.filter(cls.jti == jti).first()

    @classmethod
    def delete_expired_refresh(cls):
        filter_before = datetime.utcnow() - JWT_REFRESH_TOKEN_EXPIRES
        db.session.query(cls).filter(cls.created_at <= filter_before, cls.type ==
                                     'refresh', ~cls.created_tokens.any()).delete(synchronize_session=False)
        db.session.commit()

    @classmethod
    def delete_expired_access(cls):
        filter_before = datetime.utcnow() - JWT_ACCESS_TOKEN_EXPIRES
        db.session.query(cls).filter(cls.created_at <=
                                     filter_before, cls.type == 'access').delete()
        db.session.commit()

    # Delete oldest refresh token -> log out device
    # Used e.g. when a refresh token is used twice
    def delete_token_familiy(self):
        if (self.type != 'refresh'):
            return
        token = self
        while token:
            if token.refresh_token:
                token = token.refresh_token
            else:
                token.delete()
                token = None

    def has_created_refresh_token(self) -> bool:
        return db.session.query(Token).filter(Token.refresh_token_id == self.id, Token.type == 'refresh').count() > 0

    def delete_created_access_tokens(self):
        if (self.type != 'refresh'):
            return
        db.session.query(Token).filter(Token.refresh_token_id ==
                                       self.id, Token.type == 'access').delete()
        db.session.commit()

    @classmethod
    def create_access_token(cls, user: User, refreshTokenModel: Self) -> Tuple[any, Self]:
        accesssToken = create_access_token(identity=user)
        model = cls()
        model.jti = get_jti(accesssToken)
        model.type = 'access'
        model.name = refreshTokenModel.name
        model.user = user
        model.refresh_token = refreshTokenModel
        model.save()
        return accesssToken, model

    @classmethod
    def create_refresh_token(cls, user: User, device: str = None, oldRefreshToken: Self = None) -> Tuple[any, Self]:
        assert device or oldRefreshToken
        if (oldRefreshToken and (oldRefreshToken.type != 'refresh' or oldRefreshToken.has_created_refresh_token())):
            oldRefreshToken.delete_token_familiy()
            raise UnauthorizedRequest(
                message='Unauthorized: IP {} reused the same refresh token, loging out user'.format(request.remote_addr))

        refreshToken = create_refresh_token(identity=user)
        model = cls()
        model.jti = get_jti(refreshToken)
        model.type = 'refresh'
        model.name = device or oldRefreshToken.name
        model.user = user
        if (oldRefreshToken):
            oldRefreshToken.delete_created_access_tokens()
            model.refresh_token = oldRefreshToken
        model.save()
        return refreshToken, model

    @classmethod
    def create_longlived_token(cls, user: User, device: str) -> Tuple[any, Self]:
        accesssToken = create_access_token(identity=user, expires_delta=False)
        model = cls()
        model.jti = get_jti(accesssToken)
        model.type = 'llt'
        model.name = device
        model.user = user
        model.save()
        return accesssToken, model
