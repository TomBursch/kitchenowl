import pytest

from app import app, config
from app.config import is_allowed_socketio_origin

FRONT_URL_ORIGIN = "https://kitchenowl.example.com"
LAN_ORIGIN = "http://192.168.1.10:8099"


def socketioEnviron(host, scheme="http", forwardedProto=None, forwardedHost=None):
    environ = {"HTTP_HOST": host, "wsgi.url_scheme": scheme}
    if forwardedProto:
        environ["HTTP_X_FORWARDED_PROTO"] = forwardedProto
    if forwardedHost:
        environ["HTTP_X_FORWARDED_HOST"] = forwardedHost
    return environ


@pytest.mark.parametrize(
    "origin,environ,allowed",
    [
        # Same origin reached through different URLs (LAN IP, public domain,
        # port) is always allowed, also when FRONT_URL is set.
        (LAN_ORIGIN, socketioEnviron("192.168.1.10:8099"), True),
        (
            LAN_ORIGIN,
            socketioEnviron("192.168.1.10:8099", forwardedProto="http"),
            True,
        ),
        (
            "https://app.example.com",
            socketioEnviron(
                "kitchenowl-backend:5000",
                forwardedProto="https",
                forwardedHost="app.example.com",
            ),
            True,
        ),
        # The FRONT_URL origin is allowed even when it is a different origin
        # than the one the backend is reached on.
        (FRONT_URL_ORIGIN, socketioEnviron("192.168.1.10:8099"), True),
        # Any other cross origin is rejected.
        ("https://evil.example.com", socketioEnviron("192.168.1.10:8099"), False),
        (
            "https://evil.example.com",
            socketioEnviron("kitchenowl-backend:5000", forwardedProto="https"),
            False,
        ),
        (None, socketioEnviron("192.168.1.10:8099"), False),
        (LAN_ORIGIN, {}, False),
    ],
)
def testIsAllowedSocketioOrigin(monkeypatch, origin, environ, allowed):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN)
    assert is_allowed_socketio_origin(origin, environ) == allowed


def testIsAllowedSocketioOriginWithoutFrontUrl(monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", None)
    assert is_allowed_socketio_origin(LAN_ORIGIN, socketioEnviron("192.168.1.10:8099"))
    assert not is_allowed_socketio_origin(
        "https://evil.example.com", socketioEnviron("192.168.1.10:8099")
    )


def testIsAllowedSocketioOriginFrontUrlTrailingSlash(monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN + "/")
    assert is_allowed_socketio_origin(
        FRONT_URL_ORIGIN, socketioEnviron("192.168.1.10:8099")
    )


@pytest.fixture
def client():
    app.config["TESTING"] = True
    return app.test_client()


def testSocketioPollingSameOriginWithFrontUrl(client, monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN)
    response = client.get(
        "/socket.io/?EIO=4&transport=polling",
        base_url=LAN_ORIGIN,
        headers={"Origin": LAN_ORIGIN},
    )
    assert response.status_code == 200


def testSocketioPollingFrontUrlOrigin(client, monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN)
    response = client.get(
        "/socket.io/?EIO=4&transport=polling",
        base_url="http://kitchenowl-backend:5000",
        headers={"Origin": FRONT_URL_ORIGIN},
    )
    assert response.status_code == 200


def testSocketioPollingForeignOriginRejected(client, monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN)
    response = client.get(
        "/socket.io/?EIO=4&transport=polling",
        base_url=LAN_ORIGIN,
        headers={"Origin": "https://evil.example.com"},
    )
    assert response.status_code == 400


def testSocketioPollingWithoutOrigin(client, monkeypatch):
    monkeypatch.setattr(config, "FRONT_URL", FRONT_URL_ORIGIN)
    response = client.get(
        "/socket.io/?EIO=4&transport=polling",
        base_url=LAN_ORIGIN,
    )
    assert response.status_code == 200
