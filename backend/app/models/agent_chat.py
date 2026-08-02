"""Persisted recipe-agent chats.

A chat belongs to a single user inside a household. Messages keep the full
conversation including assistant tool calls and tool responses so that the
context can be replayed when the user sends the next message.
"""

from __future__ import annotations

import enum
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any, Self, cast

from sqlalchemy import func, select
from sqlalchemy.orm import Mapped

from app import db


def _to_utc_ms(value: datetime | None) -> int | None:
    """Serialize a (possibly naive) datetime as UTC milliseconds since epoch.

    The rest of the API serializes datetimes the same way via
    ``KitchenOwlJSONProvider`` -- we mirror it explicitly here for fields
    we have to format ourselves so the frontend can always treat them as
    timezone-aware UTC instants and convert to the user's local time.
    """
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return int(round(value.timestamp() * 1000))


Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase
    from app.models import Household, Recipe, User
    from app.models.agent_persona import AgentPersona
    from app.models.agent_recipe_card import AgentRecipeCard

    Model = DbModelBase


class AgentMessageRole(enum.Enum):
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
    TOOL = "tool"


class AgentChat(Model):
    __tablename__ = "agent_chat"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )
    user_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=False, index=True
    )
    title: Mapped[str | None] = db.Column(db.String(255))
    # ``True`` when the title was set explicitly by the user; auto-rename
    # never touches a locked title.
    title_locked: Mapped[bool] = db.Column(db.Boolean(), nullable=False, default=False)
    # ``True`` while the title is still the auto-generated truncate fallback
    # so the LLM-based rename can refine it once enough context exists.
    title_auto: Mapped[bool] = db.Column(db.Boolean(), nullable=False, default=True)
    persona_id: Mapped[int | None] = db.Column(
        db.Integer,
        db.ForeignKey("agent_persona.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    household: Mapped[Household] = cast(
        Mapped["Household"],
        db.relationship("Household", uselist=False),
    )
    user: Mapped[User] = cast(
        Mapped["User"],
        db.relationship("User", uselist=False),
    )
    persona: Mapped[AgentPersona | None] = cast(
        Mapped["AgentPersona | None"],
        db.relationship("AgentPersona", uselist=False),
    )
    messages: Mapped[list[AgentMessage]] = cast(
        Mapped[list["AgentMessage"]],
        db.relationship(
            "AgentMessage",
            back_populates="chat",
            cascade="all, delete-orphan",
            order_by="AgentMessage.id",
        ),
    )
    cards: Mapped[list[AgentRecipeCard]] = cast(
        Mapped[list["AgentRecipeCard"]],
        db.relationship(
            "AgentRecipeCard",
            back_populates="chat",
            cascade="all, delete-orphan",
            order_by="AgentRecipeCard.position, AgentRecipeCard.id",
        ),
    )

    @classmethod
    def find_for_user(cls, household_id: int, user_id: int) -> list[Self]:
        return (
            cls.query.filter(cls.household_id == household_id, cls.user_id == user_id)
            .order_by(cls.updated_at.desc())
            .all()
        )

    @classmethod
    def find_for_user_with_summary(
        cls, household_id: int, user_id: int
    ) -> list[tuple[Self, int, str | None, datetime | None]]:
        """Return chats with their message count, last user message and the
        timestamp of their most recent message in one query.

        This avoids the N+1 problem ``obj_to_dict`` would otherwise trigger
        when listing many chats: rather than loading every message of every
        chat to compute ``message_count`` / ``last_user_message`` in Python,
        the same values are computed via correlated subqueries.

        Sorting and the displayed timestamp are based on the timestamp of
        the most recent message, NOT the chat row's ``updated_at`` (which
        also bumps on metadata changes like rename / persona switch and
        would otherwise make every chat appear "modified" simultaneously).
        """
        msg_count = (
            select(func.count(AgentMessage.id))
            .where(AgentMessage.chat_id == cls.id)
            .correlate(cls)
            .scalar_subquery()
        )
        last_user = (
            select(AgentMessage.content)
            .where(
                AgentMessage.chat_id == cls.id,
                AgentMessage.role == AgentMessageRole.USER,
            )
            .order_by(AgentMessage.id.desc())
            .limit(1)
            .correlate(cls)
            .scalar_subquery()
        )
        last_msg_at = (
            select(func.max(AgentMessage.updated_at))
            .where(AgentMessage.chat_id == cls.id)
            .correlate(cls)
            .scalar_subquery()
        )
        stmt = (
            select(cls, msg_count, last_user, last_msg_at)
            .where(cls.household_id == household_id, cls.user_id == user_id)
            .order_by(func.coalesce(last_msg_at, cls.updated_at).desc())
        )
        return [
            (row[0], row[1] or 0, row[2], row[3])
            for row in db.session.execute(stmt).all()
        ]

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        # Lightweight view: avoid loading the full ``messages`` collection.
        # Use :meth:`obj_to_summary_dict` when ``message_count`` /
        # ``last_user_message`` are needed (preferred path: pre-computed via
        # :meth:`find_for_user_with_summary` to keep the query count flat).
        return super().obj_to_dict(skip_columns, include_columns)

    def obj_to_summary_dict(
        self,
        message_count: int,
        last_user_message: str | None,
        last_message_at: datetime | None = None,
    ) -> dict[str, Any]:
        res = self.obj_to_dict()
        res["message_count"] = message_count
        res["last_user_message"] = last_user_message
        # Emit as the same UTC-millisecond integer the rest of the API uses
        # (see ``KitchenOwlJSONProvider``). This keeps the frontend tz-aware
        # because a naive ``isoformat()`` string would otherwise be parsed
        # as local time on the client.
        res["last_message_at"] = _to_utc_ms(last_message_at)
        return res

    def obj_to_full_dict(self) -> dict[str, Any]:
        res = self.obj_to_dict()
        msgs = self.messages
        res["messages"] = [m.obj_to_dict() for m in msgs]
        last_user = next(
            (m for m in reversed(msgs) if m.role == AgentMessageRole.USER), None
        )
        res["message_count"] = len(msgs)
        res["last_user_message"] = last_user.content if last_user else None
        last_msg = msgs[-1] if msgs else None
        res["last_message_at"] = _to_utc_ms(last_msg.updated_at if last_msg else None)
        # Open right-side recipe cards. Imported lazily to avoid a circular
        # import at module load time.
        from app.models.agent_recipe_card import AgentRecipeCard

        res["cards"] = [
            c.obj_to_dict() for c in AgentRecipeCard.find_open_for_chat(self.id)
        ]
        return res


class AgentMessage(Model):
    __tablename__ = "agent_message"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    chat_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("agent_chat.id"), nullable=False, index=True
    )
    role: Mapped[AgentMessageRole] = db.Column(
        db.Enum(AgentMessageRole), nullable=False
    )
    content: Mapped[str | None] = db.Column(db.Text())
    # JSON-encoded list of tool calls when role == ASSISTANT and the model
    # decided to use tools. Persisted as text for portability across DBs.
    tool_calls: Mapped[str | None] = db.Column(db.Text())
    # OpenAI tool_call_id this message responds to, when role == TOOL.
    tool_call_id: Mapped[str | None] = db.Column(db.String(128))
    tool_name: Mapped[str | None] = db.Column(db.String(128))
    requires_confirmation: Mapped[bool] = db.Column(
        db.Boolean(), nullable=False, default=False
    )
    # Set when this assistant/tool turn produced a recipe so the UI can show
    # a "view recipe" affordance.
    created_recipe_id: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("recipe.id", ondelete="SET NULL")
    )
    # JSON-encoded list of inverse operations needed to undo the mutation
    # this tool message performed. Populated by ``RecipeAgent`` for tool
    # messages whose handler mutated KitchenOwl data; ``None`` otherwise
    # (read-only tools, errors, assistant/user messages). The shape is
    # ``{"ops": [{"tool": str, "type": "create"|"update"|"delete",
    # "entity": str, "entity_id": int|None, "before": dict|None,
    # "after": dict|None, "extra": dict|None}, ...]}``. The ``before`` /
    # ``after`` snapshots include the entity's ``updated_at`` so the undo
    # service can detect concurrent modifications by other users and
    # refuse to overwrite them.
    undo_snapshot: Mapped[str | None] = db.Column(db.Text())
    # JSON-encoded payload of context the user attached to this message.
    # Shape: ``{"recipe_ids": [int], "item_ids": [int]}``. Only set on
    # USER messages. The agent picks these up when building the prompt and
    # surfaces them as "attached context" to the LLM.
    attachments_json: Mapped[str | None] = db.Column(db.Text())

    chat: Mapped[AgentChat] = cast(
        Mapped["AgentChat"],
        db.relationship("AgentChat", back_populates="messages"),
    )
    created_recipe: Mapped[Recipe | None] = cast(
        Mapped["Recipe | None"],
        db.relationship("Recipe", uselist=False),
    )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = super().obj_to_dict(skip_columns, include_columns)
        if isinstance(res.get("role"), AgentMessageRole):
            res["role"] = res["role"].value
        # ``undo_snapshot`` is an internal field used by the rewind/edit
        # endpoints to invert prior tool calls. It can hold large object
        # snapshots and is of no use to the chat UI -- never expose it.
        res.pop("undo_snapshot", None)
        # The UI only needs to know whether this tool call is reversible,
        # not the full snapshot payload. ``has_undo`` is True for any
        # mutating tool call where we captured a snapshot.
        res["has_undo"] = bool(self.undo_snapshot)
        # Decode attachments JSON for the API consumer (avoids forcing the
        # frontend to parse a nested JSON string).
        if self.attachments_json:
            try:
                import json

                res["attachments"] = json.loads(self.attachments_json)
            except Exception:
                res["attachments"] = None
        else:
            res["attachments"] = None
        res.pop("attachments_json", None)
        return res
