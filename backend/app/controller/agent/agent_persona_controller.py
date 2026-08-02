"""Agent persona endpoints + per-user default persona."""

from __future__ import annotations

from flask import Blueprint, jsonify
from flask_jwt_extended import current_user, jwt_required

from app import db
from app.errors import ForbiddenRequest, InvalidUsage, NotFoundRequest
from app.helpers import RequiredRights, authorize_household, validate_args
from app.models import AgentPersona, Household, HouseholdMember

from .schemas import (
    CreateAgentPersona,
    SetDefaultPersona,
    UpdateAgentPersona,
)

agentPersonaHousehold = Blueprint("agentPersona", __name__)


def _require_agent_enabled(household_id: int) -> None:
    household = Household.find_by_id(household_id)
    if not household or not household.agent_feature:
        raise NotFoundRequest()


def _is_admin(household_id: int) -> bool:
    if not current_user:
        return False
    if getattr(current_user, "admin", False):
        return True
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    return bool(member and member.admin)


def _can_modify(persona: AgentPersona, household_id: int) -> bool:
    if persona.household_id != household_id:
        return False
    if persona.user_id is None:
        # Global persona -- only household/server admins.
        return _is_admin(household_id)
    return persona.user_id == current_user.id


@agentPersonaHousehold.route("/personas", methods=["GET"])
@jwt_required()
@authorize_household()
def list_personas(household_id):
    _require_agent_enabled(household_id)
    _ensure_default_persona(household_id)
    personas = AgentPersona.find_visible_for_user(household_id, current_user.id)
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    default_id = member.default_persona_id if member else None
    return jsonify(
        {
            "personas": [p.obj_to_dict() for p in personas],
            "user_default_persona_id": default_id,
        }
    )


def _ensure_default_persona(household_id: int) -> None:
    """Create the seeded "Standard" global persona if missing.

    The Alembic migration seeds it for existing databases, but fresh
    test databases (``db.create_all``) and brand-new households created
    after migration also need one.
    """
    if AgentPersona.find_default_global(household_id) is not None:
        return
    persona = AgentPersona(
        household_id=household_id,
        user_id=None,
        name="Standard",
        is_default_global=True,
    )
    persona.save()


@agentPersonaHousehold.route("/personas", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(CreateAgentPersona)
def create_persona(args, household_id):
    _require_agent_enabled(household_id)
    scope = args.get("scope", "private")
    if scope == "global" and not _is_admin(household_id):
        raise ForbiddenRequest()

    persona = AgentPersona(
        household_id=household_id,
        user_id=None if scope == "global" else current_user.id,
        name=args["name"].strip(),
        icon=(args.get("icon") or "").strip() or None,
        system_prompt=args.get("system_prompt"),
        initial_greeting=args.get("initial_greeting"),
        temperature=args.get("temperature"),
        is_default_global=False,
    )
    persona.save()
    return jsonify(persona.obj_to_dict())


@agentPersonaHousehold.route("/personas/<int:persona_id>", methods=["PATCH"])
@jwt_required()
@authorize_household()
@validate_args(UpdateAgentPersona)
def update_persona(args, household_id, persona_id):
    _require_agent_enabled(household_id)
    persona = AgentPersona.find_by_id(persona_id)
    if not persona or persona.household_id != household_id:
        raise NotFoundRequest()
    if not _can_modify(persona, household_id):
        raise ForbiddenRequest()

    if "name" in args:
        new_name = args["name"].strip()
        if not new_name:
            raise InvalidUsage("name must not be empty")
        persona.name = new_name
    if "icon" in args:
        persona.icon = (args["icon"] or "").strip() or None
    if "system_prompt" in args:
        persona.system_prompt = args["system_prompt"] or None
    if "initial_greeting" in args:
        persona.initial_greeting = args["initial_greeting"] or None
    if "temperature" in args:
        persona.temperature = args["temperature"]

    if "is_default_global" in args:
        if persona.user_id is not None:
            raise InvalidUsage("Only global personas can be marked as default")
        if not _is_admin(household_id):
            raise ForbiddenRequest()
        wants_default = bool(args["is_default_global"])
        if wants_default:
            # Clear any existing default in this household so there is at
            # most one global default at a time.
            others = AgentPersona.query.filter(
                AgentPersona.household_id == household_id,
                AgentPersona.user_id.is_(None),
                AgentPersona.is_default_global.is_(True),
                AgentPersona.id != persona.id,
            ).all()
            for other in others:
                other.is_default_global = False
                db.session.add(other)
            persona.is_default_global = True
        else:
            persona.is_default_global = False

    persona.save()
    return jsonify(persona.obj_to_dict())


@agentPersonaHousehold.route("/personas/<int:persona_id>", methods=["DELETE"])
@jwt_required()
@authorize_household()
def delete_persona(household_id, persona_id):
    _require_agent_enabled(household_id)
    persona = AgentPersona.find_by_id(persona_id)
    if not persona or persona.household_id != household_id:
        raise NotFoundRequest()
    if not _can_modify(persona, household_id):
        raise ForbiddenRequest()
    if persona.is_default_global:
        raise InvalidUsage("Cannot delete the default persona")
    persona.delete()
    return jsonify({"deleted": True, "id": persona_id})


@agentPersonaHousehold.route("/personas/default", methods=["PUT"])
@jwt_required()
@authorize_household()
@validate_args(SetDefaultPersona)
def set_user_default_persona(args, household_id):
    _require_agent_enabled(household_id)
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    if not member:
        raise ForbiddenRequest()
    persona_id = args.get("persona_id")
    if persona_id is None:
        member.default_persona_id = None
    else:
        persona = AgentPersona.find_for_user(household_id, persona_id, current_user.id)
        if not persona:
            raise NotFoundRequest()
        member.default_persona_id = persona.id
    member.save()
    return jsonify({"user_default_persona_id": member.default_persona_id})


# ``RequiredRights`` is intentionally referenced (re-exported) so callers
# can inspect the module the same way ``agent_config_controller`` does.
_ = RequiredRights
