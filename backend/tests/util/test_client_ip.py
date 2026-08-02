from flask import Flask

from app.errors import getClientIp


def test_forwarded_address_is_ignored_for_untrusted_peer(monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    app = Flask(__name__)
    with app.test_request_context(
        "/", headers={"X-Forwarded-For": "198.51.100.8"}, environ_base={"REMOTE_ADDR": "192.0.2.4"}
    ):
        assert getClientIp() == "192.0.2.4"


def test_forwarded_address_is_accepted_for_trusted_peer(monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    app = Flask(__name__)
    with app.test_request_context(
        "/",
        headers={"X-Forwarded-For": "198.51.100.8, 10.0.0.2"},
        environ_base={"REMOTE_ADDR": "10.0.0.2"},
    ):
        assert getClientIp() == "198.51.100.8"