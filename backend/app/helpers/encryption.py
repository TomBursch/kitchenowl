"""Symmetric encryption for sensitive data stored in the DB.

Used by :mod:`app.models.llm_config` to keep LLM provider API keys encrypted
at rest. The key is read from the ``LLM_ENCRYPTION_KEY`` env var (base64-
encoded 32 bytes, i.e. a Fernet key). If absent, a key is deterministically
derived from ``JWT_SECRET_KEY`` so existing deployments do not need to change
their configuration. Operators are advised to set ``LLM_ENCRYPTION_KEY``
explicitly: rotating the JWT secret would otherwise make stored keys
unreadable.
"""

from __future__ import annotations

import base64
import hashlib
import logging

from cryptography.fernet import Fernet, InvalidToken, MultiFernet

from app.config import get_secret

_logger = logging.getLogger(__name__)
_fernet: Fernet | MultiFernet | None = None


def _derive_key_from(secret: str) -> bytes:
    """Derive a Fernet-compatible 32-byte url-safe base64 key from ``secret``."""
    digest = hashlib.sha256(secret.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest)


def _load_fernet(value: str, variable: str) -> Fernet:
    try:
        return Fernet(value.encode("utf-8"))
    except Exception as exc:
        raise RuntimeError(
            f"{variable} is not a valid Fernet key (32 url-safe base64 bytes)."
        ) from exc


def _get_fernet() -> Fernet | MultiFernet:
    global _fernet
    if _fernet is not None:
        return _fernet

    explicit = get_secret("LLM_ENCRYPTION_KEY")
    if explicit:
        keys = [_load_fernet(explicit, "LLM_ENCRYPTION_KEY")]
        previous = get_secret("LLM_ENCRYPTION_KEY_PREVIOUS")
        if previous:
            keys.extend(
                _load_fernet(value.strip(), "LLM_ENCRYPTION_KEY_PREVIOUS")
                for value in previous.split(",")
                if value.strip()
            )
        _fernet = MultiFernet(keys) if len(keys) > 1 else keys[0]
        return _fernet

    allow_derived = (
        get_secret("DEBUG", "False").lower() == "true"
        or get_secret("ALLOW_INSECURE_SECRETS", "False").lower() == "true"
    )
    if not allow_derived:
        raise RuntimeError("LLM_ENCRYPTION_KEY must be set outside development mode")

    jwt_secret = get_secret("JWT_SECRET_KEY", "super-secret") or "super-secret"
    _logger.warning(
        "LLM_ENCRYPTION_KEY is not set; deriving it from JWT_SECRET_KEY for development"
    )
    _fernet = Fernet(_derive_key_from(jwt_secret))
    return _fernet


def encrypt_secret(plaintext: str) -> str:
    """Encrypt a secret string and return a url-safe base64 token."""
    if plaintext is None:
        raise ValueError("plaintext must not be None")
    return _get_fernet().encrypt(plaintext.encode("utf-8")).decode("utf-8")


def decrypt_secret(token: str) -> str:
    """Decrypt a token previously produced by :func:`encrypt_secret`."""
    if token is None:
        raise ValueError("token must not be None")
    try:
        return _get_fernet().decrypt(token.encode("utf-8")).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("Stored secret is unreadable (wrong encryption key?)") from exc


def reset_for_tests() -> None:
    """Forget the cached Fernet instance so a new key is read. Tests only."""
    global _fernet
    _fernet = None


# Re-export for callers that prefer importing through this module
__all__ = [
    "decrypt_secret",
    "encrypt_secret",
    "reset_for_tests",
]
