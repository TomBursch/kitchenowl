from typing import Self

from flask_jwt_extended import current_user
from app import db
from app.helpers import DbModelMixin, TimestampMixin
from app.config import bcrypt


class User(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = "user"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    username = db.Column(db.String(256), unique=True, nullable=False)
    email = db.Column(db.String(256), unique=True, nullable=True)
    password = db.Column(db.String(256), nullable=False)
    photo = db.Column(db.String(), db.ForeignKey("file.filename", use_alter=True))
    admin = db.Column(db.Boolean(), default=False)
    email_verified = db.Column(db.Boolean(), default=False)

    tokens = db.relationship(
        "Token", back_populates="user", cascade="all, delete-orphan"
    )

    password_reset_challenge = db.relationship(
        "ChallengePasswordReset", back_populates="user", cascade="all, delete-orphan"
    )
    verify_mail_challenge = db.relationship(
        "ChallengeMailVerify", back_populates="user", cascade="all, delete-orphan"
    )

    households = db.relationship(
        "HouseholdMember", back_populates="user", cascade="all, delete-orphan"
    )

    expenses_paid = db.relationship(
        "Expense", back_populates="paid_by", cascade="all, delete-orphan"
    )
    expenses_paid_for = db.relationship(
        "ExpensePaidFor", back_populates="user", cascade="all, delete-orphan"
    )
    photo_file = db.relationship(
        "File", back_populates="profile_picture", foreign_keys=[photo], uselist=False
    )

    def check_password(self, password: str) -> bool:
        return bcrypt.check_password_hash(self.password, password)

    def set_password(self, password: str):
        self.password = bcrypt.generate_password_hash(password).decode("utf-8")

    def obj_to_dict(
        self,
        include_email: bool = False,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
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
    def find_by_username(cls, username: str) -> Self:
        return cls.query.filter(cls.username == username).first()

    @classmethod
    def find_by_email(cls, email: str) -> Self:
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
            username=username.lower().strip().replace(" ", ""),
            password=bcrypt.generate_password_hash(password).decode("utf-8"),
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
        )
