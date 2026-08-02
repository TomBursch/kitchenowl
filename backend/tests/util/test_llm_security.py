from types import SimpleNamespace

import pytest

from app.config import _validate_jwt_secret
from app.helpers.safe_error import safe_error_message
from app.models.llm_config import LLMProviderType
from app.service.llm.provider import (
    LLMError,
    OpenAICompatibleProvider,
    validate_endpoint_url,
)


def test_production_jwt_secret_must_be_strong():
    with pytest.raises(RuntimeError, match="at least 32 bytes"):
        _validate_jwt_secret("PLEASE_CHANGE_ME", allow_insecure=False)
    assert _validate_jwt_secret("x" * 32, allow_insecure=False) == "x" * 32


@pytest.mark.parametrize(
    "url",
    ["file:///etc/passwd", "not-a-url", "https://user:secret@example.com/v1"],
)
def test_llm_endpoint_rejects_unsafe_url_shapes(url):
    with pytest.raises(LLMError):
        validate_endpoint_url(url)


def test_private_llm_endpoint_requires_explicit_allowlist(monkeypatch):
    monkeypatch.delenv("LLM_ALLOWED_HOSTS", raising=False)
    config = SimpleNamespace(
        provider=LLMProviderType.CUSTOM,
        effective_base_url=lambda: "http://llm.internal:11434/v1",
    )
    with pytest.raises(LLMError, match="not in LLM_ALLOWED_HOSTS"):
        OpenAICompatibleProvider(config)


def test_allowlist_explicitly_permits_private_llm_endpoint(monkeypatch):
    monkeypatch.setenv("LLM_ALLOWED_HOSTS", "llm.internal")
    config = SimpleNamespace(
        provider=LLMProviderType.CUSTOM,
        effective_base_url=lambda: "http://llm.internal:11434/v1",
    )
    OpenAICompatibleProvider(config)


def test_configured_allowlist_also_restricts_builtin_provider(monkeypatch):
    monkeypatch.setenv("LLM_ALLOWED_HOSTS", "llm.internal")
    config = SimpleNamespace(
        provider=LLMProviderType.OPENAI,
        effective_base_url=lambda: "https://api.openai.com/v1",
    )
    with pytest.raises(LLMError, match="not in LLM_ALLOWED_HOSTS"):
        OpenAICompatibleProvider(config)


def test_safe_error_message_is_single_line_and_capped():
    message = safe_error_message(ValueError("visible\n" + "secret" * 100))
    assert message == "visible"
    assert len(safe_error_message(ValueError("x" * 300))) == 200