"""LLM configuration for the recipe agent.

Stored per household. Secrets (LLM API key and Brave Search API key) are
encrypted at rest using :mod:`app.helpers.encryption`.
"""

from __future__ import annotations

import enum
from typing import TYPE_CHECKING, Any, Self, cast

from sqlalchemy.orm import Mapped

from app import db
from app.helpers.encryption import decrypt_secret, encrypt_secret

Model = db.Model
if TYPE_CHECKING:
    from app.helpers.db_model_base import DbModelBase
    from app.models import Household
    from app.models.agent_persona import AgentPersona

    Model = DbModelBase


class LLMProviderType(enum.Enum):
    """Supported LLM provider adapters.

    All adapters in V1 use an OpenAI-compatible chat-completions API via the
    bundled ``litellm`` library, so the provider only influences the default
    base URL and the model prefix that is forwarded to litellm.
    """

    OPENAI = "openai"
    GEMINI = "gemini"
    CUSTOM = "custom"


# Sensible defaults so the user only has to fill in the API key and model.
_DEFAULT_BASE_URLS: dict[LLMProviderType, str | None] = {
    LLMProviderType.OPENAI: "https://api.openai.com/v1",
    LLMProviderType.GEMINI: "https://generativelanguage.googleapis.com/v1beta/openai/",
    LLMProviderType.CUSTOM: None,
}


# Default first assistant message shown when a new agent chat is created.
# This is intentionally a friendly, open-ended opener so the agent can run a
# real dialog with the user (rather than firing off tool calls immediately).
# Operators can override this per household via ``LLMConfig.initial_greeting``.
DEFAULT_INITIAL_GREETING = (
    "Hallo! Ich bin dein KitchenOwl-Rezept-Agent. Worauf hast du heute "
    "Lust? Erzähl mir gerne, ob du etwas Schnelles oder eher Aufwendiges "
    "kochen möchtest, ob es eher leicht oder herzhaft sein soll und für "
    "wie viele Personen du planst.\n"
    "[suggestions: Schnell & leicht | Schnell & herzhaft | Aufwendig & "
    "leicht | Überrasch mich]"
)


class LLMConfig(Model):
    __tablename__ = "llm_config"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    household_id: Mapped[int] = db.Column(
        db.Integer,
        db.ForeignKey("household.id"),
        nullable=False,
        unique=True,
        index=True,
    )

    provider: Mapped[LLMProviderType] = db.Column(
        db.Enum(LLMProviderType),
        nullable=False,
        default=LLMProviderType.OPENAI,
    )
    base_url: Mapped[str | None] = db.Column(db.String(512))
    model: Mapped[str | None] = db.Column(db.String(128))
    api_key_encrypted: Mapped[str | None] = db.Column(db.String())
    brave_search_api_key_encrypted: Mapped[str | None] = db.Column(db.String())
    system_prompt: Mapped[str | None] = db.Column(db.Text())
    initial_greeting: Mapped[str | None] = db.Column(db.Text())
    # Legacy column kept so existing rows still load; the suggestion
    # guideline feature was removed in favour of per-chat recipe cards and
    # is no longer surfaced via the API or used at runtime.
    suggestion_guideline: Mapped[str | None] = db.Column(db.Text())

    enabled: Mapped[bool] = db.Column(db.Boolean(), nullable=False, default=False)
    max_tokens: Mapped[int | None] = db.Column(db.Integer)
    temperature: Mapped[float | None] = db.Column(db.Float)

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship("Household", uselist=False),
    )

    # ------------------------------------------------------------------ helpers

    @classmethod
    def find_by_household(cls, household_id: int) -> Self | None:
        return cls.query.filter(cls.household_id == household_id).first()

    @classmethod
    def get_or_create(cls, household_id: int) -> Self:
        existing = cls.find_by_household(household_id)
        if existing:
            return existing
        cfg = cls(
            household_id=household_id,
            provider=LLMProviderType.OPENAI,
            enabled=False,
        )
        cfg.save()
        return cfg

    def default_base_url(self) -> str | None:
        return _DEFAULT_BASE_URLS.get(self.provider)

    def effective_base_url(self) -> str | None:
        return (self.base_url or "").strip() or self.default_base_url()

    def effective_initial_greeting(self, persona: "AgentPersona | None" = None) -> str:
        """Return the configured greeting or the default.

        If ``persona`` is given and overrides the greeting, it wins over the
        household-level greeting.
        """
        if persona is not None:
            override = (persona.initial_greeting or "").strip()
            if override:
                return override
        return (self.initial_greeting or "").strip() or DEFAULT_INITIAL_GREETING

    def set_api_key(self, api_key: str | None) -> None:
        if api_key is None:
            return
        api_key = api_key.strip()
        if api_key == "":
            self.api_key_encrypted = None
        else:
            self.api_key_encrypted = encrypt_secret(api_key)

    def get_api_key(self) -> str | None:
        if not self.api_key_encrypted:
            return None
        return decrypt_secret(self.api_key_encrypted)

    def has_api_key(self) -> bool:
        return bool(self.api_key_encrypted)

    def set_brave_search_api_key(self, api_key: str | None) -> None:
        if api_key is None:
            return
        api_key = api_key.strip()
        if api_key == "":
            self.brave_search_api_key_encrypted = None
        else:
            self.brave_search_api_key_encrypted = encrypt_secret(api_key)

    def get_brave_search_api_key(self) -> str | None:
        if not self.brave_search_api_key_encrypted:
            return None
        return decrypt_secret(self.brave_search_api_key_encrypted)

    def has_brave_search_api_key(self) -> bool:
        return bool(self.brave_search_api_key_encrypted)

    def is_ready(self) -> bool:
        """Return True if the config has the minimum needed to call the LLM."""
        return bool(self.enabled and self.model and self.has_api_key())

    def obj_to_dict(
        self,
        skip_columns: list[str] | None = None,
        include_columns: list[str] | None = None,
    ) -> dict[str, Any]:
        # Always strip the encrypted key. We expose only ``api_key_set``.
        skip = list(skip_columns or [])
        if "api_key_encrypted" not in skip:
            skip.append("api_key_encrypted")
        if "brave_search_api_key_encrypted" not in skip:
            skip.append("brave_search_api_key_encrypted")
        # Suggestion guideline was removed as a feature; never surface it.
        if "suggestion_guideline" not in skip:
            skip.append("suggestion_guideline")
        res = super().obj_to_dict(skip_columns=skip, include_columns=include_columns)
        if "provider" in res and isinstance(res["provider"], LLMProviderType):
            res["provider"] = res["provider"].value
        res["api_key_set"] = self.has_api_key()
        res["brave_search_api_key_set"] = self.has_brave_search_api_key()
        res["effective_base_url"] = self.effective_base_url()
        res["default_base_url"] = self.default_base_url()
        return res
