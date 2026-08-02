"""LLM-backed recipe agent.

This package provides:

* :class:`LLMProvider` and :class:`OpenAICompatibleProvider` -- thin wrappers
  around ``litellm`` for chat completions with tool calling.
* :class:`RecipeAgent` -- runs the agent loop, executes tools using
  :mod:`app.service.agent_tools`, persists messages and reports the final
  assistant reply.

The provider is intentionally tiny: by going through litellm, we get OpenAI,
Google Gemini (`gemini/...` model prefix or the OpenAI-compatibility
endpoint) and any other OpenAI-compatible HTTP API for free.
"""

from .provider import LLMProvider, OpenAICompatibleProvider, get_provider, LLMError
from .agent import RecipeAgent

__all__ = [
    "LLMProvider",
    "OpenAICompatibleProvider",
    "get_provider",
    "LLMError",
    "RecipeAgent",
]
