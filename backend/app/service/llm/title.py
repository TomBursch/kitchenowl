"""Generate short, friendly titles for agent chats via the LLM."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from app.service.llm.provider import LLMError, get_provider

if TYPE_CHECKING:  # pragma: no cover - typing only
    from app.models import AgentChat, AgentMessage, LLMConfig
    from app.models.agent_persona import AgentPersona

_logger = logging.getLogger(__name__)


_TITLE_SYSTEM_PROMPT = (
    "You generate a short, descriptive title (3-6 words, no quotes, no "
    "trailing punctuation, no emojis, in the language the user is "
    "speaking) for the following recipe-agent chat. Only output the "
    "title itself, nothing else."
)

# Keep the title rename cheap: cap how much of the conversation we feed in
# and how many tokens the model is allowed to spend on the answer.
_TITLE_MAX_USER_CHARS = 600
_TITLE_MAX_ASSISTANT_CHARS = 400


def _format_for_title(messages: "list[AgentMessage]") -> str:
    from app.models import AgentMessageRole

    parts: list[str] = []
    for msg in messages:
        if msg.role == AgentMessageRole.USER:
            text = (msg.content or "").strip()[:_TITLE_MAX_USER_CHARS]
            if text:
                parts.append(f"User: {text}")
        elif msg.role == AgentMessageRole.ASSISTANT:
            text = (msg.content or "").strip()[:_TITLE_MAX_ASSISTANT_CHARS]
            if text:
                parts.append(f"Assistant: {text}")
    return "\n".join(parts)


def _sanitise_title(raw: str | None) -> str | None:
    if not raw:
        return None
    title = raw.strip()
    if not title:
        return None
    # Strip enclosing quotes the model sometimes adds.
    for quote in ('"', "'", "“", "”", "‘", "’", "«", "»"):
        if title.startswith(quote):
            title = title[len(quote) :]
        if title.endswith(quote):
            title = title[: -len(quote)]
    title = title.strip().rstrip(".!?:;,")
    # One line only -- defensive against model preamble.
    title = title.splitlines()[0].strip()
    if len(title) > 80:
        title = title[:80].rstrip()
    return title or None


def generate_chat_title(
    config: "LLMConfig",
    chat: "AgentChat",
    persona: "AgentPersona | None" = None,
) -> str | None:
    """Ask the LLM for a short title for ``chat``. Errors return ``None``."""
    if not config.is_ready():
        return None
    convo = _format_for_title(chat.messages)
    if not convo:
        return None
    try:
        # Use the household's regular provider (same model / API key) but
        # with a tiny token budget and no tool definitions so the call is
        # cheap and returns plain text. Persona overrides are intentionally
        # NOT applied here -- the title style should stay consistent
        # regardless of the persona's voice.
        provider = get_provider(config)
        response = provider.chat(
            messages=[
                {"role": "system", "content": _TITLE_SYSTEM_PROMPT},
                {"role": "user", "content": convo},
            ],
            tools=None,
            temperature=0.2,
        )
    except LLMError as exc:
        _logger.info("auto-title generation failed: %s", exc)
        return None
    except Exception as exc:  # pragma: no cover - defensive
        _logger.warning("unexpected error while generating title: %s", exc)
        return None
    # ``persona`` is currently unused but kept in the signature so callers
    # don't have to special-case the call site if we ever want to bias the
    # title language by persona.
    _ = persona
    return _sanitise_title(response.content)
