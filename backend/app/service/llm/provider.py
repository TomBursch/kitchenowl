"""LLM provider abstraction backed by ``litellm``."""

from __future__ import annotations

import ipaddress
import logging
import os
import socket
from dataclasses import dataclass, field
from typing import Any
from urllib.parse import urlparse

from app.models.llm_config import LLMConfig, LLMProviderType

_logger = logging.getLogger(__name__)
_BUILTIN_PROVIDER_HOSTS = {
    LLMProviderType.OPENAI: {"api.openai.com"},
    LLMProviderType.GEMINI: {"generativelanguage.googleapis.com"},
}


class LLMError(Exception):
    """Raised when the configured LLM endpoint cannot be reached or refuses the request."""


@dataclass
class LLMResponse:
    content: str | None
    tool_calls: list[dict[str, Any]] = field(default_factory=list)
    raw: dict[str, Any] | None = None


def _parse_allowed_hosts(env_value: str | None) -> set[str]:
    if not env_value:
        return set()
    return {h.strip().lower() for h in env_value.split(",") if h.strip()}


def validate_endpoint_url(url: str) -> str:
    """Validate an outbound HTTP endpoint and return its normalized hostname."""
    try:
        parsed = urlparse(url)
        hostname = parsed.hostname
    except ValueError as exc:
        raise LLMError("LLM endpoint URL is invalid") from exc
    if parsed.scheme not in {"http", "https"} or not hostname:
        raise LLMError("LLM endpoint URL must use http or https and include a host")
    if parsed.username or parsed.password:
        raise LLMError("LLM endpoint URL must not contain credentials")
    return hostname.lower()


def _is_non_public_address(value: str) -> bool:
    address = ipaddress.ip_address(value)
    return not address.is_global


def _model_id_for(config: LLMConfig) -> str:
    """Return the model string passed to litellm.

    For Gemini we prefer the native ``gemini/<model>`` provider so litellm
    can use the official Generative Language API; otherwise we use the
    user-supplied model verbatim, which makes litellm fall back to the
    custom ``api_base`` (OpenAI-compatible).
    """
    model = (config.model or "").strip()
    if not model:
        raise LLMError("LLM config does not have a model name")

    if config.provider == LLMProviderType.GEMINI and "/" not in model:
        return f"gemini/{model}"
    return model


class LLMProvider:
    """Base class. Subclasses implement :meth:`chat`."""

    def chat(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
        temperature: float | None = None,
    ) -> LLMResponse:
        raise NotImplementedError


class OpenAICompatibleProvider(LLMProvider):
    """Provider that delegates to ``litellm.completion``.

    Supports OpenAI, Gemini (via either the native ``gemini/`` route or the
    OpenAI-compatible REST endpoint) and arbitrary OpenAI-compatible servers
    (Ollama, vLLM, OpenRouter, LM Studio, ...).
    """

    def __init__(self, config: LLMConfig):
        self.config = config
        self._enforce_outbound_allowlist()

    # ------------------------------------------------------------------ helpers

    def _enforce_outbound_allowlist(self) -> None:
        allowed = _parse_allowed_hosts(os.getenv("LLM_ALLOWED_HOSTS"))
        base_url = self.config.effective_base_url()
        hostname = validate_endpoint_url(base_url) if base_url else None
        # Native Gemini route doesn't need a base URL but always hits Google.
        if hostname is None and self.config.provider == LLMProviderType.GEMINI:
            hostname = "generativelanguage.googleapis.com"
        if hostname is None:
            raise LLMError("The configured LLM provider has no endpoint URL")
        if allowed:
            if hostname not in allowed:
                raise LLMError(
                    f"LLM endpoint host '{hostname}' is not in LLM_ALLOWED_HOSTS"
                )
            return
        if hostname not in _BUILTIN_PROVIDER_HOSTS.get(self.config.provider, set()):
            raise LLMError(
                f"LLM endpoint host '{hostname}' is not in LLM_ALLOWED_HOSTS"
            )

        try:
            addresses = {
                item[4][0]
                for item in socket.getaddrinfo(hostname, None, type=socket.SOCK_STREAM)
            }
        except socket.gaierror as exc:
            raise LLMError(
                f"LLM endpoint host '{hostname}' cannot be resolved"
            ) from exc
        if any(_is_non_public_address(address) for address in addresses):
            raise LLMError(
                f"LLM endpoint host '{hostname}' resolves to a non-public address; "
                "add it to LLM_ALLOWED_HOSTS to allow it explicitly"
            )

    # ------------------------------------------------------------------ chat

    def chat(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
        temperature: float | None = None,
    ) -> LLMResponse:
        try:
            # Imported lazily so test code can patch the module-level name and
            # so importing this module never triggers litellm's network probes.
            from litellm import completion
        except Exception as exc:  # pragma: no cover - import-time failure
            raise LLMError(f"litellm is not available: {exc}") from exc

        kwargs: dict[str, Any] = {
            "model": _model_id_for(self.config),
            "messages": messages,
            "api_key": self.config.get_api_key(),
            "timeout": 60,
            "num_retries": 0,
        }

        base_url = self.config.effective_base_url()
        # litellm's native ``gemini/`` route talks to Google's Generative
        # Language API directly and ignores ``api_base``. Worse, if the
        # OpenAI-compatible URL is forwarded as ``api_base`` Google's REST
        # endpoint returns 404. Only forward ``api_base`` when the user
        # explicitly configured one.
        model_id = kwargs["model"]
        if base_url and not model_id.startswith("gemini/"):
            kwargs["api_base"] = base_url

        if self.config.max_tokens is not None:
            kwargs["max_tokens"] = self.config.max_tokens
        # Per-call temperature (e.g. from a persona) overrides the
        # household-level default. Falls back to ``config.temperature``.
        effective_temperature = (
            temperature if temperature is not None else self.config.temperature
        )
        if effective_temperature is not None:
            kwargs["temperature"] = effective_temperature

        if tools:
            kwargs["tools"] = tools
            kwargs["tool_choice"] = "auto"

        try:
            response = completion(**kwargs)
        except Exception as exc:
            detail = str(exc)
            for attr in ("response", "llm_provider", "message"):
                val = getattr(exc, attr, None)
                if val is not None:
                    body = getattr(val, "text", None) or getattr(val, "content", None)
                    if body:
                        detail += f" | {attr}.body={body!r}"
                    else:
                        detail += f" | {attr}={val!r}"
            _logger.warning("LLM call failed: %s\nrepr=%r", detail, exc, exc_info=True)
            raise LLMError(detail) from exc

        return _normalize_response(response)


def _normalize_response(response: Any) -> LLMResponse:
    """Normalise a litellm ``ModelResponse`` into our :class:`LLMResponse`.

    litellm exposes either an OpenAI-shaped object with attribute access or
    a plain dict, depending on the provider, so handle both.
    """

    def _g(obj: Any, key: str, default: Any = None) -> Any:
        if obj is None:
            return default
        if isinstance(obj, dict):
            return obj.get(key, default)
        return getattr(obj, key, default)

    choices = _g(response, "choices") or []
    if not choices:
        return LLMResponse(content=None, raw=_safe_dict(response))
    message = _g(choices[0], "message") or {}
    content = _g(message, "content")
    raw_tool_calls = _g(message, "tool_calls") or []

    tool_calls: list[dict[str, Any]] = []
    for tc in raw_tool_calls:
        function = _g(tc, "function") or {}
        tool_calls.append(
            {
                "id": _g(tc, "id") or "",
                "type": _g(tc, "type") or "function",
                "function": {
                    "name": _g(function, "name") or "",
                    "arguments": _g(function, "arguments") or "",
                },
            }
        )

    return LLMResponse(
        content=content if isinstance(content, str) else None,
        tool_calls=tool_calls,
        raw=_safe_dict(response),
    )


def _safe_dict(obj: Any) -> dict[str, Any] | None:
    if obj is None:
        return None
    if isinstance(obj, dict):
        return obj
    for attr in ("model_dump", "dict", "to_dict"):
        method = getattr(obj, attr, None)
        if callable(method):
            try:
                result = method()
                if isinstance(result, dict):
                    return result
            except Exception:
                continue
    return None


def get_provider(config: LLMConfig) -> LLMProvider:
    """Return the provider implementation for ``config``."""
    return OpenAICompatibleProvider(config)
