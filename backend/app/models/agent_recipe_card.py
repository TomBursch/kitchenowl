"""Right-side recipe cards shown alongside an agent chat.

Each card represents one recipe the user is currently considering inside a
specific chat. Cards are produced when:

* The user creates a new agent chat → a random existing recipe is seeded.
* The agent calls ``create_recipe`` → the freshly created recipe is added.
* (Future) the agent calls ``propose_recipe_card`` to surface a draft idea.

Closing a card removes it from the panel AND from the agent's prompt
context, so the user can curate which recipes the model continues to
reason about.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any, cast

from sqlalchemy.orm import Mapped

from app import db

Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase
    from app.models import AgentChat, Recipe

    Model = DbModelBase


# Card source values stored in ``source``.
CARD_SOURCE_EXISTING = "existing"  # picked from household recipes
CARD_SOURCE_CREATED = "created"  # produced by ``create_recipe`` tool call
CARD_SOURCE_PROPOSED = "proposed"  # draft proposal not yet saved as recipe


class AgentRecipeCard(Model):
    __tablename__ = "agent_recipe_card"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    chat_id: Mapped[int] = db.Column(
        db.Integer,
        db.ForeignKey("agent_chat.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    recipe_id: Mapped[int | None] = db.Column(
        db.Integer,
        db.ForeignKey("recipe.id", ondelete="SET NULL"),
        nullable=True,
    )
    source: Mapped[str] = db.Column(db.String(32), nullable=False)
    title: Mapped[str] = db.Column(db.String(255), nullable=False)
    description: Mapped[str | None] = db.Column(db.Text())
    payload_json: Mapped[str | None] = db.Column(db.Text())
    position: Mapped[int] = db.Column(db.Integer, nullable=False, default=0)
    # Free-form label so users can group cards inside a chat (e.g. weekday
    # names for a meal-plan or course names for a multi-course menu).
    # ``None`` means the card is ungrouped.
    group_label: Mapped[str | None] = db.Column(db.String(64), nullable=True)
    closed_at = db.Column(db.DateTime, nullable=True)

    chat: Mapped["AgentChat"] = cast(
        Mapped["AgentChat"],
        db.relationship("AgentChat", uselist=False, back_populates="cards"),
    )
    recipe: Mapped["Recipe | None"] = cast(
        Mapped["Recipe | None"],
        db.relationship("Recipe", uselist=False),
    )

    @classmethod
    def find_open_for_chat(cls, chat_id: int) -> list["AgentRecipeCard"]:
        return (
            cls.query.filter(cls.chat_id == chat_id, cls.closed_at.is_(None))
            .order_by(cls.position.asc(), cls.id.asc())
            .all()
        )

    @classmethod
    def find_all_for_chat(cls, chat_id: int) -> list["AgentRecipeCard"]:
        return (
            cls.query.filter(cls.chat_id == chat_id)
            .order_by(cls.position.asc(), cls.id.asc())
            .all()
        )

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        res = super().obj_to_dict(skip_columns, include_columns)
        res["closed"] = self.closed_at is not None
        # Payload JSON is opaque to the API consumer; pass through as-is.
        return res
