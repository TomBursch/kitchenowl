"""Per-household LLM configuration endpoints."""

from __future__ import annotations

import logging

from flask import Blueprint, jsonify
from flask_jwt_extended import current_user, jwt_required

from app.errors import InvalidUsage
from app.helpers import RequiredRights, authorize_household, validate_args
from app.helpers.safe_error import safe_error_message
from app.models import HouseholdMember, LLMConfig
from app.models.llm_config import LLMProviderType
from app.service.llm.provider import LLMError, get_provider

from .schemas import UpdateLLMConfig

agentConfigHousehold = Blueprint("agentConfig", __name__)

_logger = logging.getLogger(__name__)
_DEFAULT_GEMINI_MODEL = "gemini-flash-latest"


# Fields a non-admin household member is allowed to see. The system prompt,
# base URL etc. may contain operator-specific notes and must stay admin-only.
_MEMBER_VISIBLE_FIELDS = (
    "household_id",
    "provider",
    "model",
    "enabled",
    "api_key_set",
)


def _is_household_admin(household_id: int) -> bool:
    if not current_user:
        return False
    if getattr(current_user, "admin", False):
        return True
    member = HouseholdMember.find_by_ids(household_id, current_user.id)
    return bool(member and member.admin)


def _redact_config(full: dict) -> dict:
    return {k: full[k] for k in _MEMBER_VISIBLE_FIELDS if k in full}


@agentConfigHousehold.route("/config", methods=["GET"])
@jwt_required()
@authorize_household()
def get_config(household_id):
    cfg = LLMConfig.get_or_create(household_id)
    full = cfg.obj_to_dict()
    if _is_household_admin(household_id):
        return jsonify(full)
    # Members only see what they need to decide whether to show the chat
    # entry point: provider/model/enabled/api_key_set. Admin-only fields
    # (system prompt, base URL, tuning parameters) are stripped.
    return jsonify(_redact_config(full))


@agentConfigHousehold.route("/config", methods=["PUT"])
@jwt_required()
@authorize_household(required=RequiredRights.ADMIN)
@validate_args(UpdateLLMConfig)
def update_config(args, household_id):
    cfg = LLMConfig.get_or_create(household_id)

    if "provider" in args:
        cfg.provider = LLMProviderType(args["provider"])
    if "base_url" in args:
        cfg.base_url = (args["base_url"] or "").strip() or None
    if "model" in args:
        cfg.model = (args["model"] or "").strip() or None
    elif cfg.provider == LLMProviderType.GEMINI and not (cfg.model or "").strip():
        # When Gemini is selected without an explicit model, use the
        # lightweight multimodal default that works for image+text prompts.
        cfg.model = _DEFAULT_GEMINI_MODEL
    if "api_key" in args:
        cfg.set_api_key(args["api_key"])
    if "brave_search_api_key" in args:
        cfg.set_brave_search_api_key(args["brave_search_api_key"])
    if "system_prompt" in args:
        cfg.system_prompt = args["system_prompt"]
    if "initial_greeting" in args:
        raw = args["initial_greeting"]
        cfg.initial_greeting = (raw or "").strip() or None
    if "enabled" in args:
        cfg.enabled = bool(args["enabled"])
    if "max_tokens" in args:
        cfg.max_tokens = args["max_tokens"]
    if "temperature" in args:
        cfg.temperature = args["temperature"]

    cfg.save()
    return jsonify(cfg.obj_to_dict())


@agentConfigHousehold.route("/config/test", methods=["POST"])
@jwt_required()
@authorize_household(required=RequiredRights.ADMIN)
def test_config(household_id):
    cfg = LLMConfig.find_by_household(household_id)
    if not cfg or not cfg.model or not cfg.has_api_key():
        raise InvalidUsage("Provider, model and API key are required to run a test")

    provider = get_provider(cfg)
    try:
        response = provider.chat(
            messages=[
                {
                    "role": "system",
                    "content": "You are a connection test. Reply with the single word 'ok'.",
                },
                {"role": "user", "content": "ping"},
            ],
            tools=None,
        )
    except LLMError as exc:
        _logger.info("LLM connection test failed: %s", exc)
        return jsonify(
            {"ok": False, "error": safe_error_message(exc, "LLM provider error")}
        ), 200

    return jsonify(
        {
            "ok": True,
            "reply": (response.content or "").strip()[:200],
        }
    )
