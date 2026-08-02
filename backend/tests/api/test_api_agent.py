"""Tests for the LLM recipe-agent endpoints."""

from __future__ import annotations

import base64
import io
import json
import os
from unittest.mock import patch

from app.service.llm.provider import LLMResponse


def _config_path(household_id: int) -> str:
    return f"/api/household/{household_id}/agent/config"


def _chats_path(household_id: int) -> str:
    return f"/api/household/{household_id}/agent/chats"


def test_get_initial_config_creates_default(user_client_with_household, household_id):
    res = user_client_with_household.get(_config_path(household_id))
    assert res.status_code == 200
    body = res.get_json()
    assert body["household_id"] == household_id
    assert body["api_key_set"] is False
    assert body["brave_search_api_key_set"] is False
    assert body["enabled"] is False
    # The encrypted key column must never be exposed.
    assert "api_key_encrypted" not in body
    assert body["provider"] == "openai"
    assert body["default_base_url"]


def test_update_config_stores_encrypted_key(user_client_with_household, household_id):
    payload = {
        "provider": "gemini",
        "model": "gemini-1.5-flash",
        "api_key": "super-secret-key",
        "brave_search_api_key": "brave-secret-key",
        "system_prompt": "Vegetarisch, ohne Pilze.",
        "enabled": True,
    }
    res = user_client_with_household.put(_config_path(household_id), json=payload)
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    assert body["provider"] == "gemini"
    assert body["model"] == "gemini-1.5-flash"
    assert body["api_key_set"] is True
    assert body["brave_search_api_key_set"] is True
    assert "super-secret-key" not in json.dumps(body)
    assert "brave-secret-key" not in json.dumps(body)
    assert body["enabled"] is True

    # Reading the config back never returns the key.
    res = user_client_with_household.get(_config_path(household_id))
    assert "super-secret-key" not in res.get_data(as_text=True)


def test_clear_api_key_with_empty_string(user_client_with_household, household_id):
    user_client_with_household.put(
        _config_path(household_id),
        json={"model": "gpt-4o-mini", "api_key": "abc", "enabled": True},
    )
    res = user_client_with_household.put(
        _config_path(household_id), json={"api_key": ""}
    )
    assert res.status_code == 200
    assert res.get_json()["api_key_set"] is False


def test_clear_brave_search_api_key_with_empty_string(
    user_client_with_household, household_id
):
    user_client_with_household.put(
        _config_path(household_id),
        json={"brave_search_api_key": "abc"},
    )
    res = user_client_with_household.put(
        _config_path(household_id), json={"brave_search_api_key": ""}
    )
    assert res.status_code == 200
    assert res.get_json()["brave_search_api_key_set"] is False


def _enable_agent_feature(client, household_id):
    """Flip on the per-household agent feature flag."""
    res = client.post(
        f"/api/household/{household_id}",
        json={"agent_feature": True},
    )
    assert res.status_code == 200, res.get_data(as_text=True)


def test_create_chat_requires_configured_agent(
    user_client_with_household, household_id
):
    _enable_agent_feature(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 400


def _configure_ready_agent(client, household_id):
    _enable_agent_feature(client, household_id)
    res = client.put(
        _config_path(household_id),
        json={
            "provider": "openai",
            "model": "gpt-4o-mini",
            "api_key": "sk-test",
            "enabled": True,
        },
    )
    assert res.status_code == 200, res.get_data(as_text=True)


def test_chat_flow_runs_agent_and_creates_recipe(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)

    # 1. Create chat
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    chat_id = res.get_json()["id"]

    # 2. Script a fake provider: first turn -> tool call to create_recipe;
    #    second turn -> plain assistant reply after explicit confirmation.
    tool_call = {
        "id": "call_1",
        "type": "function",
        "function": {
            "name": "create_recipe",
            "arguments": json.dumps(
                {
                    "household_id": household_id,
                    "name": "Spaghetti Aglio e Olio",
                    "description": "1) Pasta kochen.\n2) Knoblauch in Öl braten.",
                    "yields": 2,
                    "prep_time": 5,
                    "cook_time": 10,
                    "items": [
                        {"name": "Spaghetti", "description": "200g"},
                        {"name": "Knoblauch", "description": "3 Zehen"},
                    ],
                    "tags": ["italienisch"],
                }
            ),
        },
    }
    fake_responses = iter(
        [
            LLMResponse(content=None, tool_calls=[tool_call]),
            LLMResponse(
                content="Fertig! Möchtest du noch ein Vorschlag?", tool_calls=[]
            ),
        ]
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "Schlag mir was schnelles vor."},
        )

    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    roles = [m["role"] for m in body["messages"]]
    assert roles == ["user", "assistant", "tool"]
    tool_msg = body["messages"][2]
    assert tool_msg["tool_name"] == "create_recipe"
    assert tool_msg["requires_confirmation"] is True
    assert tool_msg["created_recipe_id"] is None

    res = user_client_with_household.get(f"/api/household/{household_id}/recipe")
    assert not any(r["name"] == "Spaghetti Aglio e Olio" for r in res.get_json())

    blocked = user_client_with_household.post(
        f"{_chats_path(household_id)}/{chat_id}/messages",
        json={"content": "continue without confirming"},
    )
    assert blocked.status_code == 400

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages/{tool_msg['id']}/confirm"
        )
    assert res.status_code == 200, res.get_data(as_text=True)
    confirmed = res.get_json()["messages"]
    assert [m["role"] for m in confirmed] == ["tool", "assistant"]
    assert confirmed[0]["created_recipe_id"]
    final_assistant = confirmed[-1]
    assert "Fertig" in (final_assistant["content"] or "")

    repeated = user_client_with_household.post(
        f"{_chats_path(household_id)}/{chat_id}/messages/{tool_msg['id']}/confirm"
    )
    assert repeated.status_code == 400

    # 3. Verify the recipe really exists in the household
    res = user_client_with_household.get(f"/api/household/{household_id}/recipe")
    assert res.status_code == 200
    recipes = res.get_json()
    assert any(r["name"] == "Spaghetti Aglio e Olio" for r in recipes)


def test_delete_chat_removes_recipe_cards(user_client_with_household, household_id):
    _configure_ready_agent(user_client_with_household, household_id)

    # Create a first chat.
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    chat_id = res.get_json()["id"]

    # Create a recipe and attach it as a chat card.
    recipe_res = user_client_with_household.post(
        f"/api/household/{household_id}/recipe",
        json={
            "name": "Pinned card recipe",
            "description": "test",
            "yields": 1,
            "time": 5,
            "items": [],
        },
    )
    assert recipe_res.status_code == 200
    recipe_id = recipe_res.get_json()["id"]

    attach_res = user_client_with_household.post(
        f"{_chats_path(household_id)}/{chat_id}/cards",
        json={"recipe_id": recipe_id},
    )
    assert attach_res.status_code == 200, attach_res.get_data(as_text=True)

    cards_res = user_client_with_household.get(
        f"{_chats_path(household_id)}/{chat_id}/cards"
    )
    assert cards_res.status_code == 200
    assert len(cards_res.get_json()) == 1

    res = user_client_with_household.delete(f"{_chats_path(household_id)}/{chat_id}")
    assert res.status_code == 200

    # New chats must not inherit stale cards (regression check).
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    new_chat_id = res.get_json()["id"]

    new_cards_res = user_client_with_household.get(
        f"{_chats_path(household_id)}/{new_chat_id}/cards"
    )
    assert new_cards_res.status_code == 200
    assert new_cards_res.get_json() == []


def _upload_fixture_file(client, filename: str, data: bytes) -> str:
    from app.config import UPLOAD_FOLDER

    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    res = client.post(
        "/api/upload",
        data={"file": (io.BytesIO(data), filename)},
        content_type="multipart/form-data",
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    return res.get_json()["filename"]


def test_chat_message_with_image_attachment_is_multimodal(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    png_bytes = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
        "/x8AAwMB/ax7vF0AAAAASUVORK5CYII="
    )
    uploaded = _upload_fixture_file(user_client_with_household, "dish.png", png_bytes)

    captured: dict = {}

    def fake_chat(self, messages, tools=None, temperature=None):
        captured["messages"] = messages
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={
                "content": "Mach daraus ein Rezept",
                "attached_files": [uploaded],
            },
        )

    assert res.status_code == 200, res.get_data(as_text=True)
    user_msg = next(m for m in captured["messages"] if m["role"] == "user")
    assert isinstance(user_msg["content"], list)
    assert any(p.get("type") == "image_url" for p in user_msg["content"])


def test_chat_message_with_pdf_attachment_extracts_text(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    fake_pdf = b"%PDF-1.1\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF"
    uploaded = _upload_fixture_file(user_client_with_household, "recipe.pdf", fake_pdf)

    captured: dict = {}

    def fake_chat(self, messages, tools=None, temperature=None):
        captured["messages"] = messages
        return LLMResponse(content="ok", tool_calls=[])

    with patch(
        "app.service.llm.agent._extract_pdf_text", return_value="2 Eier\n1 TL Salz"
    ), patch(
        "app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat
    ):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={
                "content": "",
                "attached_files": [uploaded],
            },
        )

    assert res.status_code == 200, res.get_data(as_text=True)
    user_msg = next(m for m in captured["messages"] if m["role"] == "user")
    assert isinstance(user_msg["content"], list)
    text_parts = [p.get("text") for p in user_msg["content"] if p.get("type") == "text"]
    assert any("2 Eier" in (t or "") for t in text_parts)


def test_chat_message_attachment_only_is_allowed(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    png_bytes = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
        "/x8AAwMB/ax7vF0AAAAASUVORK5CYII="
    )
    uploaded = _upload_fixture_file(user_client_with_household, "dish.png", png_bytes)

    def fake_chat(self, messages, tools=None, temperature=None):
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "", "attached_files": [uploaded]},
        )

    assert res.status_code == 200, res.get_data(as_text=True)
    roles = [m["role"] for m in res.get_json()["messages"]]
    assert roles == ["user", "assistant"]


def test_chat_message_reports_granular_attachment_errors(
    user_client_with_household, household_id, caplog
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    uploaded_txt = _upload_fixture_file(
        user_client_with_household,
        "notes.txt",
        b"this is plain text",
    )

    with caplog.at_level("WARNING"):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={
                "content": "",
                "attached_files": [uploaded_txt, "missing-file-id.pdf"],
            },
        )

    assert res.status_code == 400
    detailed = "\n".join(r.message for r in caplog.records)
    assert "Invalid attached files:" in detailed
    assert f"{uploaded_txt}: unsupported type" in detailed
    assert "missing-file-id.pdf: not found" in detailed


def test_duplicate_file_ids_are_deduplicated_before_limit_check(
    user_client_with_household, household_id
):
    """Duplicate IDs must be de-duplicated before the max-files limit is checked.

    Previously the limit was enforced on the raw (pre-dedup) list, so 11 entries
    of the same file would incorrectly raise a 400 even though only 1 unique file
    was attached.  After the fix the limit is applied to the unique count.
    """
    from unittest.mock import patch

    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    png_bytes = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
        "/x8AAwMB/ax7vF0AAAAASUVORK5CYII="
    )
    uploaded = _upload_fixture_file(user_client_with_household, "img.png", png_bytes)

    # Send 11 copies of the same file ID – unique count is 1, well within the limit.
    duplicate_ids = [uploaded] * 11

    def fake_chat(self, messages, tools=None, temperature=None):
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "test", "attached_files": duplicate_ids},
        )

    assert res.status_code == 200, res.get_data(as_text=True)


def test_agent_attached_files_are_not_deleted_as_unused(
    user_client_with_household, household_id
):
    """Files referenced in agent message attachments must not be deleted by the
    monthly cleanup job (``deleteUnusedFiles``), even though they have no direct
    model relation (recipe / household / expense / profile picture).
    """
    from unittest.mock import patch

    from app.models import File
    from app.service.delete_unused import deleteUnusedFiles

    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    png_bytes = base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
        "/x8AAwMB/ax7vF0AAAAASUVORK5CYII="
    )
    uploaded = _upload_fixture_file(
        user_client_with_household, "keep_me.png", png_bytes
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "use this image", "attached_files": [uploaded]},
        )
    assert res.status_code == 200, res.get_data(as_text=True)

    # The File record has no recipe/household/expense FK so isUnused() returns True.
    from app import app as flask_app

    with flask_app.app_context():
        f = File.find(uploaded)
        assert f is not None
        assert f.isUnused(), "Precondition: file should be considered unused on its own"

        # But deleteUnusedFiles must protect it because it appears in attachments_json.
        deleted = deleteUnusedFiles()
        assert deleted == 0, f"Expected 0 deletions, got {deleted}"
        assert File.find(uploaded) is not None, "File was incorrectly deleted"


def test_update_config_sets_gemini_default_model_when_missing(
    user_client_with_household, household_id
):
    _enable_agent_feature(user_client_with_household, household_id)
    res = user_client_with_household.put(
        _config_path(household_id),
        json={
            "provider": "gemini",
            "api_key": "sk-test",
            "enabled": True,
        },
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    assert res.get_json()["model"] == "gemini-flash-latest"


def test_chat_message_surfaces_provider_error(user_client_with_household, household_id):
    from app.service.llm.provider import LLMError

    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    def boom(self, messages, tools=None, temperature=None):
        raise LLMError("network exploded")

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=boom):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "hi"},
        )
    assert res.status_code == 200
    messages = res.get_json()["messages"]
    assert messages[-1]["role"] == "assistant"
    assert "network exploded" not in messages[-1]["content"]
    assert "provider request failed" in messages[-1]["content"]


def test_chat_is_private_to_creating_user(
    user_client_with_household, household_id, admin_username, admin_password
):
    _configure_ready_agent(user_client_with_household, household_id)
    # User creates a chat
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    chat_id = res.get_json()["id"]

    # Re-login as the server admin (different user, not a household member)
    # using the same Flask test client so we get a fresh JWT.
    res = user_client_with_household.post(
        "/api/auth", json={"username": admin_username, "password": admin_password}
    )
    assert res.status_code == 200
    admin_token = res.get_json()["access_token"]
    user_client_with_household.environ_base["HTTP_AUTHORIZATION"] = (
        f"Bearer {admin_token}"
    )

    # Admin reads it -> must be denied (403) since chats are per-user, even
    # though server admins bypass household authorization.
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    assert res.status_code == 403


def test_test_endpoint_reports_provider_failure(
    user_client_with_household, household_id
):
    from app.service.llm.provider import LLMError

    _configure_ready_agent(user_client_with_household, household_id)

    def boom(self, messages, tools=None, temperature=None):
        raise LLMError("invalid api key")

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=boom):
        res = user_client_with_household.post(f"{_config_path(household_id)}/test")
    assert res.status_code == 200
    body = res.get_json()
    assert body["ok"] is False
    assert "invalid api key" in body["error"]


def test_test_endpoint_returns_reply_on_success(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)

    def fake(self, messages, tools=None, temperature=None):
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake):
        res = user_client_with_household.post(f"{_config_path(household_id)}/test")
    assert res.status_code == 200
    body = res.get_json()
    assert body == {"ok": True, "reply": "ok"}


def test_health_advertises_feature_flag(client):
    res = client.get("/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V")
    assert res.status_code == 200
    assert res.get_json()["feature_llm_agent"] is True


def test_get_config_redaction_for_non_admins():
    """Members must never receive admin-only fields like the system prompt."""
    from app.controller.agent.agent_config_controller import (
        _MEMBER_VISIBLE_FIELDS,
        _redact_config,
    )

    full = {
        "id": 1,
        "household_id": 7,
        "provider": "openai",
        "model": "gpt-4o-mini",
        "enabled": True,
        "api_key_set": True,
        "system_prompt": "secret operator prompt",
        "base_url": "https://internal/api",
        "effective_base_url": "https://internal/api",
        "default_base_url": "https://api.openai.com/v1",
        "max_tokens": 1024,
        "temperature": 0.7,
    }
    redacted = _redact_config(full)
    assert set(redacted.keys()) <= set(_MEMBER_VISIBLE_FIELDS)
    assert "system_prompt" not in redacted
    assert "base_url" not in redacted
    assert redacted["api_key_set"] is True
    assert redacted["enabled"] is True


def test_agent_cannot_call_list_households_tool(
    user_client_with_household, household_id
):
    """``list_households`` must not be exposed to the agent's tool list."""
    from app.service.llm.agent import _build_tools_schema

    tool_names = {t["function"]["name"] for t in _build_tools_schema()}
    assert "list_households" not in tool_names
    # Sanity: legitimate tools are still present.
    assert "create_recipe" in tool_names


def test_agent_overrides_household_id_arg(user_client_with_household, household_id):
    """The agent must force ``household_id`` to its bound chat household."""
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    captured: dict = {}

    other_household_id = household_id + 999  # any value the LLM might forge

    tool_call = {
        "id": "call_x",
        "type": "function",
        "function": {
            "name": "create_recipe",
            "arguments": json.dumps(
                {
                    # Try to escape the chat's household:
                    "household_id": other_household_id,
                    "name": "Boundary Test Soup",
                    "description": "1) test",
                    "items": [{"name": "Water", "description": "1l"}],
                }
            ),
        },
    }
    fake_responses = iter(
        [
            LLMResponse(content=None, tool_calls=[tool_call]),
            LLMResponse(content="done", tool_calls=[]),
        ]
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    from app.service.agent_tools import TOOLS

    real_create = TOOLS["create_recipe"][1]

    def spy_create(args):
        captured["household_id"] = args.get("household_id")
        return real_create(args)

    TOOLS["create_recipe"] = (TOOLS["create_recipe"][0], spy_create)
    try:
        with patch(
            "app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat
        ):
            res = user_client_with_household.post(
                f"{_chats_path(household_id)}/{chat_id}/messages",
                json={"content": "create something"},
            )
            pending = next(
                message
                for message in res.get_json()["messages"]
                if message["requires_confirmation"]
            )
            res = user_client_with_household.post(
                f"{_chats_path(household_id)}/{chat_id}/messages/{pending['id']}/confirm"
            )
    finally:
        TOOLS["create_recipe"] = (TOOLS["create_recipe"][0], real_create)

    assert res.status_code == 200, res.get_data(as_text=True)
    # household_id seen by the tool must be the chat's, not the LLM-supplied one.
    assert captured["household_id"] == household_id
    assert captured["household_id"] != other_household_id


def test_initial_greeting_default_when_unset(user_client_with_household, household_id):
    """A new chat shows the built-in default greeting when no override is set."""
    from app.models.llm_config import DEFAULT_INITIAL_GREETING

    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    body = res.get_json()
    assert body["messages"]
    first = body["messages"][0]
    assert first["role"] == "assistant"
    assert first["content"] == DEFAULT_INITIAL_GREETING


def test_initial_greeting_override(user_client_with_household, household_id):
    """A custom initial_greeting from settings is used as the first message."""
    _configure_ready_agent(user_client_with_household, household_id)
    custom = "Hi! Was kochen wir heute?\n[suggestions: Pasta | Salat | Suppe]"
    res = user_client_with_household.put(
        _config_path(household_id), json={"initial_greeting": custom}
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    assert body["initial_greeting"] == custom

    res = user_client_with_household.post(_chats_path(household_id), json={})
    assert res.status_code == 200
    first = res.get_json()["messages"][0]
    assert first["role"] == "assistant"
    assert first["content"] == custom


def test_initial_greeting_blank_falls_back_to_default(
    user_client_with_household, household_id
):
    """Saving a blank/whitespace greeting clears the override."""
    _configure_ready_agent(user_client_with_household, household_id)
    user_client_with_household.put(
        _config_path(household_id), json={"initial_greeting": "Custom"}
    )
    res = user_client_with_household.put(
        _config_path(household_id), json={"initial_greeting": "   "}
    )
    assert res.status_code == 200
    assert res.get_json()["initial_greeting"] is None


def test_member_cannot_see_initial_greeting():
    """Non-admin members must not receive the initial_greeting field."""
    from app.controller.agent.agent_config_controller import (
        _MEMBER_VISIBLE_FIELDS,
        _redact_config,
    )

    full = {
        "id": 1,
        "household_id": 7,
        "provider": "openai",
        "model": "gpt-4o-mini",
        "enabled": True,
        "api_key_set": True,
        "system_prompt": "secret",
        "initial_greeting": "secret greeting",
        "base_url": None,
    }
    redacted = _redact_config(full)
    assert "initial_greeting" not in redacted
    assert "initial_greeting" not in _MEMBER_VISIBLE_FIELDS


# ---------------------------------------------------------------------------
# Personas + chat rename + auto-title
# ---------------------------------------------------------------------------


def _personas_path(household_id: int) -> str:
    return f"/api/household/{household_id}/agent/personas"


def test_persona_crud_and_visibility(user_client_with_household, household_id):
    _configure_ready_agent(user_client_with_household, household_id)

    # The migration seeds one global "Standard" persona for the household.
    res = user_client_with_household.get(_personas_path(household_id))
    assert res.status_code == 200
    body = res.get_json()
    assert "personas" in body
    seeded = [p for p in body["personas"] if p["scope"] == "global"]
    assert len(seeded) >= 1
    assert any(p.get("is_default_global") for p in seeded)

    # Create a private persona.
    res = user_client_with_household.post(
        _personas_path(household_id),
        json={
            "name": "Edelkoch",
            "icon": "restaurant",
            "system_prompt": "Antworte als Sterneküchenchef.",
            "initial_greeting": "Bonsoir!",
            "temperature": 0.4,
            "scope": "private",
        },
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    persona = res.get_json()
    assert persona["scope"] == "private"
    assert persona["name"] == "Edelkoch"
    persona_id = persona["id"]

    # Update it.
    res = user_client_with_household.patch(
        f"{_personas_path(household_id)}/{persona_id}",
        json={"name": "Sternekoch", "temperature": 0.2},
    )
    assert res.status_code == 200
    assert res.get_json()["name"] == "Sternekoch"

    # Set as the user's default.
    res = user_client_with_household.put(
        f"{_personas_path(household_id)}/default",
        json={"persona_id": persona_id},
    )
    assert res.status_code == 200
    assert res.get_json()["user_default_persona_id"] == persona_id

    # Delete it.
    res = user_client_with_household.delete(
        f"{_personas_path(household_id)}/{persona_id}"
    )
    assert res.status_code == 200

    res = user_client_with_household.get(_personas_path(household_id))
    assert all(p["id"] != persona_id for p in res.get_json()["personas"])


def test_persona_default_global_cannot_be_deleted(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.get(_personas_path(household_id))
    default = next(p for p in res.get_json()["personas"] if p.get("is_default_global"))
    res = user_client_with_household.delete(
        f"{_personas_path(household_id)}/{default['id']}"
    )
    assert res.status_code == 400


def test_create_chat_uses_persona_greeting(user_client_with_household, household_id):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(
        _personas_path(household_id),
        json={
            "name": "Freunde",
            "initial_greeting": "Yo, was kochen wir?",
            "scope": "private",
        },
    )
    persona_id = res.get_json()["id"]

    res = user_client_with_household.post(
        _chats_path(household_id), json={"persona_id": persona_id}
    )
    assert res.status_code == 200
    body = res.get_json()
    assert body["persona_id"] == persona_id
    assert body["messages"][0]["content"] == "Yo, was kochen wir?"


def test_chat_rename_locks_title_then_clear_unlocks(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    # Manual rename → locked.
    res = user_client_with_household.patch(
        f"{_chats_path(household_id)}/{chat_id}",
        json={"title": "Mein Lieblingschat"},
    )
    assert res.status_code == 200
    body = res.get_json()
    assert body["title"] == "Mein Lieblingschat"
    assert body["title_locked"] is True
    assert body["title_auto"] is False

    # Empty rename → cleared and auto-rename re-enabled.
    res = user_client_with_household.patch(
        f"{_chats_path(household_id)}/{chat_id}",
        json={"title": ""},
    )
    assert res.status_code == 200
    body = res.get_json()
    assert body["title"] is None
    assert body["title_locked"] is False
    assert body["title_auto"] is True


def test_auto_title_truncates_first_message_and_does_not_overwrite_lock(
    user_client_with_household, household_id
):
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    def fake_chat(self, messages, tools=None, temperature=None):
        return LLMResponse(content="ok", tool_calls=[])

    long_msg = "Schlag mir bitte ein einfaches schnelles Pasta-Rezept vor"
    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": long_msg},
        )
    assert res.status_code == 200
    title = res.get_json()["chat"]["title"]
    assert title is not None and len(title) <= 50
    assert title.startswith("Schlag mir bitte")

    # Lock the title manually.
    user_client_with_household.patch(
        f"{_chats_path(household_id)}/{chat_id}",
        json={"title": "Pinned"},
    )

    # Second user message would normally trigger LLM rename, but lock holds.
    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "Und was zum Nachtisch?"},
        )
    assert res.status_code == 200
    assert res.get_json()["chat"]["title"] == "Pinned"


def test_persona_temperature_override_is_used(user_client_with_household, household_id):
    """A persona's temperature must be passed to the provider."""
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(
        _personas_path(household_id),
        json={"name": "Cool", "temperature": 0.1, "scope": "private"},
    )
    persona_id = res.get_json()["id"]
    res = user_client_with_household.post(
        _chats_path(household_id), json={"persona_id": persona_id}
    )
    chat_id = res.get_json()["id"]

    seen = {}

    def fake_chat(self, messages, tools=None, temperature=None):
        seen["temperature"] = temperature
        return LLMResponse(content="hi", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "ping"},
        )
    assert res.status_code == 200
    assert seen["temperature"] == 0.1


def test_persona_system_prompt_keeps_recipe_formatting_rules(
    user_client_with_household, household_id
):
    """A persona must add flavour but never override the recipe-formatting
    protocol (ingredient @-pills, propose-then-confirm, capitalisation, ...).
    """
    _configure_ready_agent(user_client_with_household, household_id)
    res = user_client_with_household.post(
        _personas_path(household_id),
        json={
            "name": "Edelkoch",
            "scope": "private",
            "system_prompt": "Speak like a Michelin-starred chef and prefer luxurious ingredients.",
        },
    )
    persona_id = res.get_json()["id"]
    res = user_client_with_household.post(
        _chats_path(household_id), json={"persona_id": persona_id}
    )
    chat_id = res.get_json()["id"]

    captured = {}

    def fake_chat(self, messages, tools=None, temperature=None):
        # Capture the system message (always first).
        captured["system"] = messages[0]["content"]
        return LLMResponse(content="ok", tool_calls=[])

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "ping"},
        )
    assert res.status_code == 200
    system = captured["system"]
    # The persona text must be present...
    assert "Michelin-starred chef" in system
    # ...but the formatting protocol from DEFAULT_SYSTEM_PROMPT must remain.
    assert "ingredient-pill" in system
    assert "create_recipe" in system
    # And the additional-guidance section must explicitly subordinate the
    # persona to the formatting rules.
    assert "must NOT override" in system


# ============================================================================
# Rewind / edit / regenerate tests
# ============================================================================


def _create_chat_with_recipe(client, household_id):
    """Configure agent, create a chat, run a tool-call that creates a recipe.

    Returns ``(chat_id, recipe_id, tool_message_id, assistant_message_id)``.
    """
    _configure_ready_agent(client, household_id)
    res = client.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    tool_call = {
        "id": "call_r1",
        "type": "function",
        "function": {
            "name": "create_recipe",
            "arguments": json.dumps(
                {
                    "household_id": household_id,
                    "name": "Undo Test Pasta",
                    "description": "1) Boil. 2) Eat.",
                    "items": [{"name": "Pasta", "description": "200g"}],
                }
            ),
        },
    }
    fake_responses = iter(
        [
            LLMResponse(content=None, tool_calls=[tool_call]),
            LLMResponse(content="Done!", tool_calls=[]),
        ]
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = client.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "make pasta"},
        )
        pending = next(
            message
            for message in res.get_json()["messages"]
            if message["requires_confirmation"]
        )
        res = client.post(
            f"{_chats_path(household_id)}/{chat_id}/messages/{pending['id']}/confirm"
        )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    msgs = body["messages"]
    tool_msg = next(m for m in msgs if m["role"] == "tool")
    assistant_final = msgs[-1]
    assert tool_msg["created_recipe_id"]
    return (
        chat_id,
        tool_msg["created_recipe_id"],
        tool_msg["id"],
        assistant_final["id"],
    )


def _msg_path(household_id, chat_id, message_id):
    return f"/api/household/{household_id}/agent/chats/{chat_id}/messages/{message_id}"


def test_tool_message_has_undo_flag(user_client_with_household, household_id):
    chat_id, _, tool_id, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    assert res.status_code == 200
    msgs = res.get_json()["messages"]
    tool_msg = next(m for m in msgs if m["id"] == tool_id)
    assert tool_msg["has_undo"] is True
    # Internal snapshot must never leak via the API.
    assert "undo_snapshot" not in tool_msg


def test_rewind_preview_lists_reversible_recipe(
    user_client_with_household, household_id
):
    chat_id, recipe_id, tool_id, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    # Find the user message (first message in chat) and rewind to it.
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")

    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind"},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    assert "preview" in body
    assert "messages_to_delete" in body
    assert tool_id in body["messages_to_delete"]
    # Preview should contain a reversible create_recipe op.
    create_ops = [p for p in body["preview"] if p.get("tool") == "create_recipe"]
    assert create_ops, body["preview"]
    assert create_ops[0]["reversible"] is True
    assert create_ops[0]["entity_id"] == recipe_id

    # Preview is a no-op: recipe still exists, messages still there.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 200


def test_rewind_confirm_undoes_recipe_and_truncates(
    user_client_with_household, household_id
):
    chat_id, recipe_id, _, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    msgs = res.get_json()["messages"]
    user_msg = next(m for m in msgs if m["role"] == "user")
    later_ids = {m["id"] for m in msgs if m["id"] > user_msg["id"]}

    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind", "confirm": True},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    assert body["skipped"] == []
    remaining_ids = {m["id"] for m in body["messages"]}
    assert remaining_ids.isdisjoint(later_ids)
    assert user_msg["id"] in remaining_ids

    # Recipe must be gone.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 404


def test_rewind_skip_undo_keeps_recipe(user_client_with_household, household_id):
    chat_id, recipe_id, tool_id, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")

    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={
            "action": "rewind",
            "confirm": True,
            "skip_undo_message_ids": [tool_id],
        },
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    # Recipe must survive because we skipped its tool message.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 200


def test_rewind_detects_external_recipe_modification(
    user_client_with_household, household_id
):
    chat_id, recipe_id, _, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    # Externally modify the recipe -- different field, new updated_at.
    res = user_client_with_household.post(
        f"/api/recipe/{recipe_id}",
        json={"name": "Renamed By Human"},
    )
    assert res.status_code == 200, res.get_data(as_text=True)

    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")

    # Preview should mark the create_recipe op non-reversible (conflict).
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind"},
    )
    assert res.status_code == 200
    create_ops = [
        p for p in res.get_json()["preview"] if p.get("tool") == "create_recipe"
    ]
    assert create_ops
    assert create_ops[0]["reversible"] is False
    assert create_ops[0]["reason"] == "conflict"

    # Confirm: recipe must NOT be deleted; conflict reported in skipped.
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind", "confirm": True},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    skipped = res.get_json()["skipped"]
    assert any(
        s["reason"] == "conflict" and s["tool"] == "create_recipe" for s in skipped
    )

    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 200
    assert res.get_json()["name"] == "Renamed By Human"


def test_edit_user_message_changes_content_and_truncates(
    user_client_with_household, household_id
):
    chat_id, recipe_id, _, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")

    fake_responses = iter([LLMResponse(content="ok, soup it is", tool_calls=[])])

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.patch(
            _msg_path(household_id, chat_id, user_msg["id"]),
            json={
                "action": "edit",
                "new_content": "actually make soup instead",
                "confirm": True,
            },
        )
    assert res.status_code == 200, res.get_data(as_text=True)
    msgs = res.get_json()["messages"]
    # Greeting (assistant) + edited user message + fresh assistant reply.
    assert len(msgs) == 3
    edited = next(m for m in msgs if m["id"] == user_msg["id"])
    assert edited["content"] == "actually make soup instead"
    # New assistant turn was generated automatically.
    assert msgs[-1]["role"] == "assistant"
    assert (msgs[-1]["content"] or "").startswith("ok, soup it is")
    # Recipe undone.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 404


def test_edit_rejects_non_user_message(user_client_with_household, household_id):
    chat_id, _, tool_id, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, tool_id),
        json={"action": "edit", "new_content": "nope", "confirm": True},
    )
    assert res.status_code == 400


def test_regenerate_replays_assistant_turn(user_client_with_household, household_id):
    chat_id, recipe_id, _, assistant_id = _create_chat_with_recipe(
        user_client_with_household, household_id
    )

    fake_responses = iter([LLMResponse(content="regenerated reply", tool_calls=[])])

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            _msg_path(household_id, chat_id, assistant_id) + "/regenerate",
            json={"confirm": True},
        )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    # Recipe should have been undone.
    res2 = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res2.status_code == 404
    # New messages contain a fresh assistant reply (the server appends a
    # ``[suggestions: ...]`` fallback marker if the model omits one, so
    # match by ``startswith`` rather than equality).
    assert any(
        m["role"] == "assistant"
        and (m.get("content") or "").startswith("regenerated reply")
        for m in body["messages"]
    )


def test_regenerate_preview_without_confirm_does_nothing(
    user_client_with_household, household_id
):
    chat_id, recipe_id, _, assistant_id = _create_chat_with_recipe(
        user_client_with_household, household_id
    )
    res = user_client_with_household.post(
        _msg_path(household_id, chat_id, assistant_id) + "/regenerate",
        json={},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    body = res.get_json()
    assert "preview" in body
    assert "messages_to_delete" in body
    # Recipe untouched.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 200


def test_rewind_after_create_then_update_in_same_chat_deletes_recipe(
    user_client_with_household, household_id
):
    """Regression: create_recipe + later update_recipe in the SAME chat.

    Rewinding the whole chat must succeed without flagging a conflict —
    the create_recipe undo (DELETE) cascades over the intermediate
    update, which is also part of the rewind batch.
    """
    chat_id, recipe_id, _, _ = _create_chat_with_recipe(
        user_client_with_household, household_id
    )

    # Second turn in the same chat: agent updates the just-created recipe.
    update_call = {
        "id": "call_u2",
        "type": "function",
        "function": {
            "name": "update_recipe",
            "arguments": json.dumps(
                {
                    "household_id": household_id,
                    "recipe_id": recipe_id,
                    "name": "Renamed By Agent",
                }
            ),
        },
    }
    fake_responses = iter(
        [
            LLMResponse(content=None, tool_calls=[update_call]),
            LLMResponse(content="renamed", tool_calls=[]),
        ]
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "rename it"},
        )
        pending = next(
            message
            for message in res.get_json()["messages"]
            if message["requires_confirmation"]
        )
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages/{pending['id']}/confirm"
        )
    assert res.status_code == 200, res.get_data(as_text=True)

    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.get_json()["name"] == "Renamed By Agent"

    # Rewind to the very first user message.
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")

    # Preview must mark create_recipe reversible despite the later update.
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind"},
    )
    assert res.status_code == 200
    create_ops = [
        p for p in res.get_json()["preview"] if p.get("tool") == "create_recipe"
    ]
    assert create_ops and create_ops[0]["reversible"] is True, res.get_json()["preview"]

    # Confirm: nothing skipped, recipe gone.
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind", "confirm": True},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    assert res.get_json()["skipped"] == []

    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 404


def test_update_recipe_undo_restores_previous_name(
    user_client_with_household, household_id
):
    """Run an agent loop that creates a recipe THEN updates it; rewinding
    must restore the original name (and not delete the recipe, since the
    latest mutation was an update)."""
    _configure_ready_agent(user_client_with_household, household_id)

    # First, create the recipe via the API directly so it predates the chat.
    res = user_client_with_household.post(
        f"/api/household/{household_id}/recipe",
        json={
            "name": "Original Name",
            "description": "x",
            "items": [],
        },
    )
    assert res.status_code == 200
    recipe_id = res.get_json()["id"]

    # New chat, agent updates the recipe.
    res = user_client_with_household.post(_chats_path(household_id), json={})
    chat_id = res.get_json()["id"]

    tool_call = {
        "id": "call_u1",
        "type": "function",
        "function": {
            "name": "update_recipe",
            "arguments": json.dumps(
                {
                    "household_id": household_id,
                    "recipe_id": recipe_id,
                    "name": "Agent Name",
                }
            ),
        },
    }
    fake_responses = iter(
        [
            LLMResponse(content=None, tool_calls=[tool_call]),
            LLMResponse(content="renamed", tool_calls=[]),
        ]
    )

    def fake_chat(self, messages, tools=None, temperature=None):
        return next(fake_responses)

    with patch("app.service.llm.provider.OpenAICompatibleProvider.chat", new=fake_chat):
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages",
            json={"content": "rename it"},
        )
        pending = next(
            message
            for message in res.get_json()["messages"]
            if message["requires_confirmation"]
        )
        res = user_client_with_household.post(
            f"{_chats_path(household_id)}/{chat_id}/messages/{pending['id']}/confirm"
        )
    assert res.status_code == 200, res.get_data(as_text=True)

    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.get_json()["name"] == "Agent Name"

    # Rewind to user message.
    res = user_client_with_household.get(f"{_chats_path(household_id)}/{chat_id}")
    user_msg = next(m for m in res.get_json()["messages"] if m["role"] == "user")
    res = user_client_with_household.patch(
        _msg_path(household_id, chat_id, user_msg["id"]),
        json={"action": "rewind", "confirm": True},
    )
    assert res.status_code == 200, res.get_data(as_text=True)
    assert res.get_json()["skipped"] == []

    # Recipe still exists with original name.
    res = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert res.status_code == 200
    assert res.get_json()["name"] == "Original Name"
