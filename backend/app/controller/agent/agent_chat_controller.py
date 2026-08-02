"""Recipe-agent chat endpoints."""

from __future__ import annotations

import logging
from datetime import UTC, datetime

from flask import Blueprint, jsonify
from flask_jwt_extended import current_user, jwt_required

from app import db, socketio
from app.errors import ForbiddenRequest, InvalidUsage, NotFoundRequest
from app.helpers import authorize_household, validate_args
from app.models import (
    CARD_SOURCE_EXISTING,
    AgentChat,
    AgentMessage,
    AgentMessageRole,
    AgentPersona,
    AgentRecipeCard,
    Household,
    HouseholdMember,
    LLMConfig,
    Recipe,
)
from app.service.agent_undo import (
    build_undo_preview,
    execute_undo_for_messages,
)
from app.service.llm.agent import RecipeAgent

from .schemas import (
    AttachRecipeCard,
    CreateAgentChat,
    PostAgentMessage,
    RegenerateAgentMessage,
    RewindAgentMessage,
    UpdateAgentChat,
    UpdateRecipeCard,
)

agentChatHousehold = Blueprint("agentChat", __name__)
_logger = logging.getLogger(__name__)


def _require_agent_enabled(household_id: int) -> None:
    household = Household.find_by_id(household_id)
    if not household or not household.agent_feature:
        raise NotFoundRequest()


def _get_owned_chat(household_id: int, chat_id: int) -> AgentChat:
    chat = AgentChat.find_by_id(chat_id)
    if not chat or chat.household_id != household_id:
        raise NotFoundRequest()
    if chat.user_id != current_user.id:
        # Chats are private to the user that started them.
        raise ForbiddenRequest()
    return chat


@agentChatHousehold.route("/chats", methods=["GET"])
@jwt_required()
@authorize_household()
def list_chats(household_id):
    _require_agent_enabled(household_id)
    rows = AgentChat.find_for_user_with_summary(household_id, current_user.id)
    return jsonify(
        [
            c.obj_to_summary_dict(count, last, last_at)
            for c, count, last, last_at in rows
        ]
    )


@agentChatHousehold.route("/chats", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(CreateAgentChat)
def create_chat(args, household_id):
    _require_agent_enabled(household_id)
    cfg = LLMConfig.find_by_household(household_id)
    if not cfg or not cfg.is_ready():
        raise InvalidUsage("LLM agent is not configured for this household")

    title = (args.get("title") or "").strip() or None

    persona = _resolve_persona_for_create(household_id, args.get("persona_id"))

    chat = AgentChat(
        household_id=household_id,
        user_id=current_user.id,
        title=title,
        title_locked=bool(title),
        title_auto=not title,
        persona_id=persona.id if persona else None,
    )
    chat.save()

    greeting = AgentMessage(
        chat_id=chat.id,
        role=AgentMessageRole.ASSISTANT,
        content=cfg.effective_initial_greeting(persona),
    )
    greeting.save()

    # Recipe cards are intentionally chat-exclusive and start empty so the
    # user fully controls which recipes belong to this chat (either by
    # adding existing ones from the household collection or by letting the
    # agent create new ones via ``create_recipe``).

    return jsonify(chat.obj_to_full_dict())


def _resolve_persona_for_create(
    household_id: int, persona_id: int | None
) -> AgentPersona | None:
    """Pick the persona to attach to a new chat.

    Order:

    1. Explicit ``persona_id`` from the request (must be visible to user).
    2. The user's saved default persona for this household.
    3. The household's global default persona.
    4. ``None`` (chat has no persona, agent uses household defaults).
    """
    if persona_id is not None:
        persona = AgentPersona.find_for_user(household_id, persona_id, current_user.id)
        if not persona:
            raise NotFoundRequest()
        return persona

    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if member and member.default_persona_id:
        persona = AgentPersona.find_for_user(
            household_id, member.default_persona_id, current_user.id
        )
        if persona:
            return persona

    return AgentPersona.find_default_global(household_id)


@agentChatHousehold.route("/chats/<int:chat_id>", methods=["GET"])
@jwt_required()
@authorize_household()
def get_chat(household_id, chat_id):
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    return jsonify(chat.obj_to_full_dict())


@agentChatHousehold.route("/chats/<int:chat_id>", methods=["DELETE"])
@jwt_required()
@authorize_household()
def delete_chat(household_id, chat_id):
    chat = _get_owned_chat(household_id, chat_id)
    # Keep chat deletion robust even on DBs/environments where FK cascade
    # is not enforced (e.g. SQLite with foreign_keys pragma disabled).
    for card in AgentRecipeCard.query.filter(AgentRecipeCard.chat_id == chat.id).all():
        db.session.delete(card)
    chat.delete()
    return jsonify({"deleted": True, "id": chat_id})


@agentChatHousehold.route("/chats/<int:chat_id>", methods=["PATCH"])
@jwt_required()
@authorize_household()
@validate_args(UpdateAgentChat)
def update_chat(args, household_id, chat_id):
    """Manual rename. Empty/whitespace title clears the lock so auto-rename
    can take over again on the next message.

    Also supports changing the chat's persona, but only while the chat has
    no user-authored messages yet — switching persona mid-conversation is
    rejected so prior assistant turns stay consistent with their persona.
    """
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)

    if "persona_id" in args:
        if any(m.role == AgentMessageRole.USER for m in chat.messages):
            raise InvalidUsage("Cannot change persona once the chat has user messages")
        persona = _resolve_persona_for_create(household_id, args["persona_id"])
        chat.persona_id = persona.id if persona else None
        # Replace the seeded assistant greeting so the chat reflects the new
        # persona's opening line. The greeting is always the first message
        # created by ``create_chat`` (and the only one when no user message
        # has been sent yet).
        cfg = LLMConfig.find_by_household(household_id)
        if cfg is not None:
            new_greeting = cfg.effective_initial_greeting(persona)
            assistant_msgs = [
                m for m in chat.messages if m.role == AgentMessageRole.ASSISTANT
            ]
            if assistant_msgs:
                # Update the earliest assistant message (the seeded greeting).
                # AgentChat.messages is ordered by id, so the smallest id is
                # the first message ever stored on this chat.
                assistant_msgs.sort(key=lambda m: m.id or 0)
                assistant_msgs[0].content = new_greeting
                assistant_msgs[0].save()

    if "title" in args:
        raw = args.get("title")
        new_title = (raw or "").strip() if raw is not None else ""
        if not new_title:
            chat.title = None
            chat.title_locked = False
            chat.title_auto = True
        else:
            chat.title = new_title[:255]
            chat.title_locked = True
            chat.title_auto = False

    chat.save()
    updated_chat_dict = chat.obj_to_full_dict()
    socketio.emit(
        "agent_chat:update",
        {"chat": updated_chat_dict},
        to="household/" + str(household_id),
    )
    return jsonify(updated_chat_dict)


@agentChatHousehold.route("/chats/<int:chat_id>/messages", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(PostAgentMessage)
def post_message(args, household_id, chat_id):
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    cfg = LLMConfig.find_by_household(household_id)
    if not cfg or not cfg.is_ready():
        raise InvalidUsage("LLM agent is not configured for this household")

    agent = RecipeAgent(cfg, chat)
    try:
        new_messages = agent.send_user_message(
            args["content"],
            attached_recipe_ids=args.get("attached_recipe_ids") or [],
            attached_item_ids=args.get("attached_item_ids") or [],
            attached_file_ids=args.get("attached_files") or [],
        )
    except InvalidUsage:
        raise
    except Exception:
        db.session.rollback()
        _logger.exception("Agent message failed")
        raise InvalidUsage("Agent request failed")

    # Notify other connected clients (and the chat list view this user has
    # open in another tab / behind the chat page) that this chat now has a
    # new last message and possibly an updated auto-title. Without this
    # the overview keeps showing the stale title and last_message_at until
    # the user manually refreshes.
    socketio.emit(
        "agent_chat:update",
        {"chat": chat.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(
        {
            "chat": chat.obj_to_dict(),
            "messages": [message.obj_to_dict() for message in new_messages],
        }
    )


@agentChatHousehold.route(
    "/chats/<int:chat_id>/messages/<int:message_id>/confirm", methods=["POST"]
)
@jwt_required()
@authorize_household()
def confirm_tool_call(household_id, chat_id, message_id):
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    cfg = LLMConfig.find_by_household(household_id)
    if not cfg or not cfg.is_ready():
        raise InvalidUsage("LLM agent is not configured for this household")

    pending = (
        AgentMessage.query.filter_by(id=message_id, chat_id=chat.id)
        .with_for_update()
        .first()
    )
    if not pending or not pending.requires_confirmation:
        raise InvalidUsage("Tool call is not pending confirmation")

    agent = RecipeAgent(cfg, chat)
    try:
        new_messages = agent.confirm_tool_batch(pending)
    except InvalidUsage:
        raise
    except Exception:
        db.session.rollback()
        _logger.exception("Agent tool confirmation failed")
        raise InvalidUsage("Agent tool confirmation failed")

    socketio.emit(
        "agent_chat:update",
        {"chat": chat.obj_to_full_dict()},
        to="household/" + str(household_id),
    )
    return jsonify(
        {
            "chat": chat.obj_to_dict(),
            "messages": [message.obj_to_dict() for message in new_messages],
        }
    )


def _messages_after(chat: AgentChat, message_id: int) -> list[AgentMessage]:
    """Return chat messages strictly *after* ``message_id`` (in order)."""
    return [m for m in chat.messages if m.id > message_id]


def _find_target_message(chat: AgentChat, message_id: int) -> AgentMessage:
    for m in chat.messages:
        if m.id == message_id:
            return m
    raise NotFoundRequest()


@agentChatHousehold.route(
    "/chats/<int:chat_id>/messages/<int:message_id>", methods=["PATCH"]
)
@jwt_required()
@authorize_household()
@validate_args(RewindAgentMessage)
def rewind_or_edit_message(args, household_id, chat_id, message_id):
    """Rewind chat history to a message, optionally editing its content.

    Two-stage protocol:

    * Without ``confirm``: returns ``preview`` listing every reversible /
      irreversible / conflicted op that *would* run, without changing
      anything. The UI shows this so the user can opt out of undoing
      individual mutations (e.g. a recipe they want to keep).
    * With ``confirm=true``: actually undoes the ops (skipping
      ``skip_undo_message_ids``), truncates the chat to the target
      message and -- when ``action == "edit"`` -- updates the target
      user message's content and re-runs the agent loop so a fresh
      assistant reply is produced. For plain ``rewind`` the loop is
      not re-run.
    """
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    target = _find_target_message(chat, message_id)

    action = args["action"]
    if action == "edit" and target.role != AgentMessageRole.USER:
        raise InvalidUsage("Only user messages can be edited")

    cfg = None
    if action == "edit":
        cfg = LLMConfig.find_by_household(household_id)
        if not cfg or not cfg.is_ready():
            raise InvalidUsage("LLM agent is not configured for this household")

    later = _messages_after(chat, message_id)

    if not args.get("confirm"):
        return jsonify(
            {
                "preview": build_undo_preview(later),
                "messages_to_delete": [m.id for m in later],
            }
        )

    new_content = (args.get("new_content") or "").strip()
    if action == "edit" and not new_content:
        raise InvalidUsage("new_content is required when action == 'edit'")

    skip_ids = set(args.get("skip_undo_message_ids") or [])

    skipped = execute_undo_for_messages(later, skip_ids)

    # Delete the messages now that their side effects have been reverted.
    for m in later:
        db.session.delete(m)

    if action == "edit":
        target.content = new_content[:4000]

    chat.updated_at = datetime.now(UTC)
    db.session.commit()

    new_messages: list[AgentMessage] = []
    if action == "edit":
        agent = RecipeAgent(cfg, chat)
        try:
            new_messages = agent.replay_loop()
        except InvalidUsage:
            raise
        except Exception:
            db.session.rollback()
            _logger.exception("Agent edit replay failed")
            raise InvalidUsage("Agent request failed")

    return jsonify(
        {
            "skipped": skipped,
            "chat": chat.obj_to_dict(),
            "messages": [m.obj_to_dict() for m in chat.messages],
            "new_messages": [m.obj_to_dict() for m in new_messages],
        }
    )


@agentChatHousehold.route(
    "/chats/<int:chat_id>/messages/<int:message_id>/regenerate", methods=["POST"]
)
@jwt_required()
@authorize_household()
@validate_args(RegenerateAgentMessage)
def regenerate_message(args, household_id, chat_id, message_id):
    """Re-run the agent starting from the user message right before ``message_id``.

    The target message must be an ASSISTANT turn (or one of its TOOL
    follow-ups). Everything from the target onwards is undone & deleted,
    then the agent loop replays against the now-trailing user message.
    """
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    cfg = LLMConfig.find_by_household(household_id)
    if not cfg or not cfg.is_ready():
        raise InvalidUsage("LLM agent is not configured for this household")

    target = _find_target_message(chat, message_id)
    if target.role not in (AgentMessageRole.ASSISTANT, AgentMessageRole.TOOL):
        raise InvalidUsage("Can only regenerate from an assistant or tool message")

    # Find the start of the assistant turn that contains ``target``: walk
    # backwards from target until we hit the first ASSISTANT message that
    # itself follows a USER message. Everything from that ASSISTANT
    # onwards is the turn we want to replace.
    ordered = sorted(chat.messages, key=lambda m: m.id)
    target_index = next(i for i, m in enumerate(ordered) if m.id == target.id)
    turn_start_index = target_index
    for i in range(target_index, -1, -1):
        if ordered[i].role == AgentMessageRole.ASSISTANT:
            turn_start_index = i
            # Stop at the first ASSISTANT preceded by a USER (= turn start).
            if i > 0 and ordered[i - 1].role == AgentMessageRole.USER:
                break

    if (
        turn_start_index == 0
        or ordered[turn_start_index - 1].role != AgentMessageRole.USER
    ):
        raise InvalidUsage(
            "Cannot regenerate: no user message precedes this assistant turn"
        )

    to_remove = ordered[turn_start_index:]

    if not args.get("confirm"):
        return jsonify(
            {
                "preview": build_undo_preview(to_remove),
                "messages_to_delete": [m.id for m in to_remove],
            }
        )

    skip_ids = set(args.get("skip_undo_message_ids") or [])
    skipped = execute_undo_for_messages(to_remove, skip_ids)

    for m in to_remove:
        db.session.delete(m)
    db.session.commit()

    # Re-run the loop against the now-trailing user message.
    agent = RecipeAgent(cfg, chat)
    try:
        new_messages = agent.replay_loop()
    except InvalidUsage:
        raise
    except Exception:
        db.session.rollback()
        _logger.exception("Agent regeneration failed")
        raise InvalidUsage("Agent request failed")

    return jsonify(
        {
            "skipped": skipped,
            "chat": chat.obj_to_dict(),
            "messages": [m.obj_to_dict() for m in new_messages],
        }
    )


# --------------------------------------------------------------- recipe cards


@agentChatHousehold.route("/chats/<int:chat_id>/cards", methods=["GET"])
@jwt_required()
@authorize_household()
def list_cards(household_id, chat_id):
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    cards = AgentRecipeCard.find_open_for_chat(chat.id)
    return jsonify([c.obj_to_dict() for c in cards])


@agentChatHousehold.route(
    "/chats/<int:chat_id>/cards/<int:card_id>/close", methods=["POST"]
)
@jwt_required()
@authorize_household()
def close_card(household_id, chat_id, card_id):
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    card = AgentRecipeCard.query.filter(
        AgentRecipeCard.id == card_id, AgentRecipeCard.chat_id == chat.id
    ).first()
    if not card:
        raise NotFoundRequest()
    if card.closed_at is None:
        card.closed_at = datetime.now(UTC)
        db.session.commit()
    return jsonify({"closed": True, "id": card_id})


@agentChatHousehold.route("/chats/<int:chat_id>/cards", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AttachRecipeCard)
def attach_recipe_card(args, household_id, chat_id):
    """Attach an existing household recipe to this chat as a recipe card.

    Cards are chat-exclusive: a recipe attached to one chat does NOT show up
    on the other chats' panels. The same recipe may, however, be attached to
    multiple chats independently.
    """
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)

    recipe = Recipe.find_by_id(args["recipe_id"])
    if not recipe or recipe.household_id != household_id:
        raise NotFoundRequest()

    # Avoid duplicates: if the same recipe is already attached & open, just
    # return the existing card so the UI can highlight it.
    existing = AgentRecipeCard.query.filter(
        AgentRecipeCard.chat_id == chat.id,
        AgentRecipeCard.recipe_id == recipe.id,
        AgentRecipeCard.closed_at.is_(None),
    ).first()
    if existing is not None:
        if args.get("group_label") is not None:
            existing.group_label = (args.get("group_label") or "").strip()[:64] or None
            db.session.commit()
        return jsonify(existing.obj_to_dict())

    # Append at the end of the panel.
    next_pos = (
        db.session.query(db.func.coalesce(db.func.max(AgentRecipeCard.position), -1))
        .filter(AgentRecipeCard.chat_id == chat.id)
        .scalar()
        or -1
    ) + 1

    group_label = args.get("group_label")
    if group_label is not None:
        group_label = group_label.strip()[:64] or None

    card = AgentRecipeCard(
        chat_id=chat.id,
        recipe_id=recipe.id,
        source=CARD_SOURCE_EXISTING,
        title=(recipe.name or "Rezept")[:255],
        description=(recipe.description or "")[:400] or None,
        position=next_pos,
        group_label=group_label,
    )
    db.session.add(card)
    db.session.commit()
    return jsonify(card.obj_to_dict())


@agentChatHousehold.route("/chats/<int:chat_id>/cards/<int:card_id>", methods=["PATCH"])
@jwt_required()
@authorize_household()
@validate_args(UpdateRecipeCard)
def update_card(args, household_id, chat_id, card_id):
    """Update a card's group label and/or position.

    Pass ``group_label`` as ``""`` or ``null`` to clear the group.
    """
    _require_agent_enabled(household_id)
    chat = _get_owned_chat(household_id, chat_id)
    card = AgentRecipeCard.query.filter(
        AgentRecipeCard.id == card_id, AgentRecipeCard.chat_id == chat.id
    ).first()
    if not card:
        raise NotFoundRequest()

    if "group_label" in args:
        raw = args.get("group_label")
        if raw is None:
            card.group_label = None
        else:
            cleaned = raw.strip()[:64]
            card.group_label = cleaned or None
    if "position" in args and args["position"] is not None:
        card.position = max(0, int(args["position"]))
    db.session.commit()
    return jsonify(card.obj_to_dict())
