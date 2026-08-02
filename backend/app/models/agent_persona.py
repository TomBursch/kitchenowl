"""Persisted agent personas.

A persona is a lightweight overlay on top of the household's :class:`LLMConfig`.
It can override the system prompt, initial greeting and temperature so the
same provider/model/API key can be reused under different "characters"
(e.g. "Edelkoch", "Familienkoch", "schnell & einfach").

Personas can be either:

* **global** (``user_id IS NULL``) -- managed by household admins and visible
  to every member.
* **private** (``user_id`` set) -- created by individual members for their
  own use; never visible to others.

Each household has exactly one global default persona that is used when a
chat is created without an explicit ``persona_id``.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any, Self, cast

from sqlalchemy import or_
from sqlalchemy.orm import Mapped

from app import db


Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase
    from app.models import Household, User

    Model = DbModelBase


class AgentPersona(Model):
    __tablename__ = "agent_persona"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )
    # ``NULL`` means "global persona managed by admins".
    user_id: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True, index=True
    )

    name: Mapped[str] = db.Column(db.String(128), nullable=False)
    icon: Mapped[str | None] = db.Column(db.String(64))
    system_prompt: Mapped[str | None] = db.Column(db.Text())
    initial_greeting: Mapped[str | None] = db.Column(db.Text())
    temperature: Mapped[float | None] = db.Column(db.Float)
    is_default_global: Mapped[bool] = db.Column(
        db.Boolean(), nullable=False, default=False
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship("Household", uselist=False),
    )
    user: Mapped["User | None"] = cast(
        Mapped["User | None"],
        db.relationship("User", uselist=False),
    )

    # ------------------------------------------------------------------ scope

    @property
    def scope(self) -> str:
        return "private" if self.user_id else "global"

    # ---------------------------------------------------------------- lookups

    @classmethod
    def find_visible_for_user(cls, household_id: int, user_id: int) -> list[Self]:
        """Return every persona the user may see in this household."""
        return (
            cls.query.filter(
                cls.household_id == household_id,
                or_(cls.user_id.is_(None), cls.user_id == user_id),
            )
            .order_by(
                cls.is_default_global.desc(), cls.user_id.is_(None).desc(), cls.id.asc()
            )
            .all()
        )

    @classmethod
    def find_default_global(cls, household_id: int) -> Self | None:
        return cls.query.filter(
            cls.household_id == household_id,
            cls.user_id.is_(None),
            cls.is_default_global.is_(True),
        ).first()

    @classmethod
    def find_for_user(
        cls, household_id: int, persona_id: int, user_id: int
    ) -> Self | None:
        """Return persona ``persona_id`` if visible to ``user_id``."""
        return cls.query.filter(
            cls.id == persona_id,
            cls.household_id == household_id,
            or_(cls.user_id.is_(None), cls.user_id == user_id),
        ).first()

    # ------------------------------------------------------------ serialisation

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = super().obj_to_dict(skip_columns, include_columns)
        res["scope"] = self.scope
        return res
