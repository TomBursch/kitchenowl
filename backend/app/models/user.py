from typing import Optional, Self, List, TYPE_CHECKING, cast

from flask_jwt_extended import current_user
from app import db
from app.config import bcrypt
from sqlalchemy.orm import Mapped
from sqlalchemy import DateTime
from datetime import datetime, timezone

Model = db.Model
if TYPE_CHECKING:
    from app.models import (
        Token,
        ChallengePasswordReset,
        ChallengeMailVerify,
        HouseholdMember,
        Expense,
        ExpensePaidFor,
        File,
        OIDCLink,
        OIDCRequest,
    )
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class User(Model):
    __tablename__ = "user"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))
    username: Mapped[str] = db.Column(
        db.String(256),
        unique=True,
        nullable=False,
        index=True,
    )
    email: Mapped[Optional[str]] = db.Column(
        db.String(256),
        unique=True,
        nullable=True,
        index=True,
    )
    password: Mapped[Optional[str]] = db.Column(db.String(256), nullable=True)
    photo: Mapped[str | None] = db.Column(
        db.String(), db.ForeignKey("file.filename", use_alter=True)
    )
    admin: Mapped[bool] = db.Column(db.Boolean(), default=False)
    email_verified: Mapped[bool] = db.Column(db.Boolean(), default=False)
    last_seen: Mapped[Optional[datetime]] = db.Column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=True
    )

    tokens: Mapped[List["Token"]] = cast(
        Mapped[List["Token"]],
        db.relationship(
            "Token",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )

    password_reset_challenge: Mapped[List["ChallengePasswordReset"]] = cast(
        Mapped[List["ChallengePasswordReset"]],
        db.relationship(
            "ChallengePasswordReset",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )
    verify_mail_challenge: Mapped[List["ChallengeMailVerify"]] = cast(
        Mapped[List["ChallengeMailVerify"]],
        db.relationship(
            "ChallengeMailVerify",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )

    households: Mapped[List["HouseholdMember"]] = cast(
        Mapped[List["HouseholdMember"]],
        db.relationship(
            "HouseholdMember",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )

    expenses_paid: Mapped[List["Expense"]] = cast(
        Mapped[List["Expense"]],
        db.relationship(
            "Expense",
            back_populates="paid_by",
            cascade="all, delete-orphan",
        ),
    )
    expenses_paid_for: Mapped[List["ExpensePaidFor"]] = cast(
        Mapped[List["ExpensePaidFor"]],
        db.relationship(
            "ExpensePaidFor",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )
    photo_file: Mapped["File"] = cast(
        Mapped["File"],
        db.relationship(
            "File",
            back_populates="profile_picture",
            foreign_keys=[photo],
            uselist=False,
        ),
    )

    oidc_links: Mapped[List["OIDCLink"]] = cast(
        Mapped[List["OIDCLink"]],
        db.relationship(
            "OIDCLink",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )
    oidc_link_requests: Mapped[List["OIDCRequest"]] = cast(
        Mapped[List["OIDCRequest"]],
        db.relationship(
            "OIDCRequest",
            back_populates="user",
            cascade="all, delete-orphan",
        ),
    )

    def check_password(self, password: str) -> bool:
        return bool(self.password) and bcrypt.check_password_hash(
            self.password, password
        )

    def set_password(self, password: str):
        self.password = bcrypt.generate_password_hash(password).decode("utf-8")

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
        include_email: bool = False,
    ) -> dict:
        if skip_columns:
            skip_columns = skip_columns + ["password"]
        else:
            skip_columns = ["password"]
        if not include_email:
            skip_columns += ["email", "email_verified"]

        if not current_user or not current_user.admin:
            # Filter out admin status if current user is not an admin
            skip_columns = skip_columns + ["admin"]

        return super().obj_to_dict(
            skip_columns=skip_columns, include_columns=include_columns
        )

    def obj_to_full_dict(self) -> dict:
        from .token import Token

        res = self.obj_to_dict(include_email=True)
        res["admin"] = self.admin
        tokens = Token.query.filter(
            Token.user_id == self.id,
            Token.type != "access",
            ~Token.created_tokens.any(Token.type == "refresh"),
        ).all()
        res["tokens"] = [e.obj_to_dict(skip_columns=["user_id"]) for e in tokens]
        res["oidc_links"] = [e.provider for e in self.oidc_links]
        return res

    def delete(self):
        """
        Delete this instance of model from db
        """
        from app.models import File

        for f in File.query.filter(File.created_by == self.id).all():
            f.created_by = None
            f.save()
        from app.models import ShoppinglistItems

        for s in ShoppinglistItems.query.filter(
            ShoppinglistItems.created_by == self.id
        ).all():
            s.created_by = None
            s.save()
        super().delete()

    @classmethod
    def find_by_username(cls, username: str) -> Self | None:
        return cls.query.filter(cls.username == username).first()

    @classmethod
    def find_by_email(cls, email: str) -> Self | None:
        return cls.query.filter(cls.email == email.strip()).first()

    @classmethod
    def create(
        cls,
        username: str,
        password: str,
        name: str,
        email: str | None = None,
        admin: bool = False,
    ) -> Self:
        return cls(
            username=username.lower().replace(" ", ""),
            password=bcrypt.generate_password_hash(password).decode("utf-8")
            if password
            else None,
            name=name.strip(),
            email=email.strip() if email else None,
            admin=admin,
        ).save()

    @classmethod
    def search_name(cls, name: str) -> list[Self]:
        if "*" in name or "_" in name:
            looking_for = name.replace("_", "__").replace("*", "%").replace("?", "_")
        else:
            looking_for = "%{0}%".format(name)
        return (
            cls.query.filter(
                cls.name.ilike(looking_for) | cls.username.ilike(looking_for)
            )
            .order_by(cls.name)
            .limit(15)
            .all()
        )
