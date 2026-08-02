import pytest
from cryptography.fernet import Fernet

from app.helpers.encryption import decrypt_secret, encrypt_secret, reset_for_tests


def test_round_trip():
    reset_for_tests()
    cipher = encrypt_secret("hello-world")
    assert cipher != "hello-world"
    assert decrypt_secret(cipher) == "hello-world"


def test_distinct_ciphertexts_for_same_plaintext():
    reset_for_tests()
    a = encrypt_secret("same")
    b = encrypt_secret("same")
    # Fernet uses a random IV, so ciphertexts must differ.
    assert a != b
    assert decrypt_secret(a) == "same"
    assert decrypt_secret(b) == "same"


def test_key_rotation_decrypts_with_previous_key(monkeypatch):
    previous = Fernet.generate_key().decode()
    current = Fernet.generate_key().decode()

    monkeypatch.setenv("LLM_ENCRYPTION_KEY", previous)
    monkeypatch.delenv("LLM_ENCRYPTION_KEY_PREVIOUS", raising=False)
    reset_for_tests()
    old_cipher = encrypt_secret("rotate-me")

    monkeypatch.setenv("LLM_ENCRYPTION_KEY", current)
    monkeypatch.setenv("LLM_ENCRYPTION_KEY_PREVIOUS", previous)
    reset_for_tests()
    assert decrypt_secret(old_cipher) == "rotate-me"

    new_cipher = encrypt_secret("new-secret")
    assert Fernet(current.encode()).decrypt(new_cipher.encode()).decode() == "new-secret"


def test_encryption_key_is_required_outside_development(monkeypatch):
    monkeypatch.delenv("LLM_ENCRYPTION_KEY", raising=False)
    monkeypatch.delenv("LLM_ENCRYPTION_KEY_PREVIOUS", raising=False)
    monkeypatch.setenv("DEBUG", "False")
    monkeypatch.delenv("ALLOW_INSECURE_SECRETS", raising=False)
    reset_for_tests()

    with pytest.raises(RuntimeError, match="LLM_ENCRYPTION_KEY must be set"):
        encrypt_secret("must-fail")

    reset_for_tests()
