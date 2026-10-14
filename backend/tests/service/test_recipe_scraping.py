import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest
import requests

from app.errors import ForbiddenRequest
from app.service import recipe_scraping

try:
    from requests_hardened.ip_filter import InvalidIPAddress as BlockedIPError
except ImportError:  # pragma: no cover - fallback for older lib versions
    BlockedIPError = requests.exceptions.ConnectionError


class _RecordingHandler(BaseHTTPRequestHandler):
    """
    Stand-in for an "internal" HTTP service that the backend process can
    reach (bound to the loopback interface), but that an untrusted caller
    must never be able to make the backend fetch.
    """

    def do_GET(self):
        if self.path == "/recipe/1":
            body = b"<html><head><title>KitchenOwl</title></head><body></body></html>"
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/api/recipe/1":
            payload = {
                "id": 1,
                "name": "internal secret recipe",
                "photo": None,
                "items": [],
            }
            body = json.dumps(payload).encode()
            self.server.internal_hits += 1
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.send_header("Content-Length", "0")
            self.end_headers()

    def log_message(self, *args):
        pass


@pytest.fixture
def internal_server():
    server = HTTPServer(("127.0.0.1", 0), _RecordingHandler)
    server.internal_hits = 0
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield server
    finally:
        server.shutdown()
        server.server_close()


class _FakeResponse:
    def __init__(self, status_code: int, text: str):
        self.status_code = status_code
        self.text = text

    def json(self):
        return json.loads(self.text)


def _recipe_payload() -> str:
    return json.dumps(
        {
            "id": 42,
            "name": "Pancakes",
            "photo": None,
            "description": "fluffy",
            "items": [{"name": "Flour", "description": "100 g"}],
        }
    )


class _FakeManager:
    """
    Test double for requests_hardened.Manager: unlike the real one it does
    not perform IP filtering itself, so each test decides per target which
    behaviour the hardened client must exhibit.
    """

    def __init__(self, responses=None, error_for=None, default_error=None):
        self.calls = []
        self.responses = responses or {}
        self.error_for = error_for or {}
        self.default_error = default_error

    def send_request(self, method, url):
        self.calls.append((method, url))
        if url in self.error_for:
            raise self.error_for[url]
        if url in self.responses:
            return self.responses[url]
        if self.default_error is not None:
            raise self.default_error
        return _FakeResponse(200, _recipe_payload())


def test_scrape_detected_instance_api_fetch_is_blocked_for_internal_addresses(
    internal_server, monkeypatch
):
    """
    A page that identifies itself as a KitchenOwl instance must not make the
    backend fetch that page origin through an unfiltered HTTP client: the
    detection origin comes from the submitted URL (regex group 1), so it is
    fully attacker-controlled and the follow-up request must inherit the
    hardened manager IP filtering.

    The first (hardened) fetch of the submitted URL is stubbed with a
    response whose page title claims to be a KitchenOwl instance, because a
    real attacker hosts that page on a public address the IP filter allows.
    The follow-up fetch targets the loopback-bound internal server and must
    be refused by the hardened manager, so no internal request may be
    observable and the scrape must degrade to unsupported.
    """
    port = internal_server.server_address[1]
    url = f"http://127.0.0.1:{port}/recipe/1"
    api_url = f"http://127.0.0.1:{port}/api/recipe/1"

    fake_manager = _FakeManager(
        responses={
            url: _FakeResponse(
                200, "<html><head><title>KitchenOwl</title></head></html>"
            ),
        },
        error_for={api_url: BlockedIPError(api_url)},
    )
    monkeypatch.setattr(recipe_scraping, "request_manager", fake_manager)

    result = recipe_scraping.scrape(url, household=None)

    # The follow-up API fetch must have been routed through the hardened
    # manager, been refused there, and never reached the internal server.
    assert any(target == api_url for _, target in fake_manager.calls)
    assert result is None
    assert internal_server.internal_hits == 0


def test_request_manager_rejects_internal_addresses(internal_server):
    """
    Documents the protection level the hardened manager already applies, and
    that the instance-detection follow-up fetch must therefore inherit.
    """
    port = internal_server.server_address[1]
    url = f"http://127.0.0.1:{port}/api/recipe/1"

    with pytest.raises(requests.RequestException):
        recipe_scraping.request_manager.send_request("GET", url)

    assert internal_server.internal_hits == 0


def test_scrape_kitchenowl_uses_the_hardened_http_client(monkeypatch):
    """
    The API fetch for a detected KitchenOwl instance must be issued through
    request_manager (IP filtering, no loopback, hardened redirects, default
    timeout), never through a plain requests call.
    """
    calls = {"plain": []}
    fake_manager = _FakeManager()

    def fake_requests_get(target, *args, **kwargs):
        calls["plain"].append(target)
        return _FakeResponse(200, _recipe_payload())

    monkeypatch.setattr(recipe_scraping, "request_manager", fake_manager)
    monkeypatch.setattr(recipe_scraping.requests, "get", fake_requests_get)

    result = recipe_scraping.scrapeKitchenOwl(
        "https://app.kitchenowl.org/recipe/42", "https://app.kitchenowl.org/api", 42
    )

    expected_call = ("GET", "https://app.kitchenowl.org/api/recipe/42")
    assert fake_manager.calls == [expected_call]
    assert calls["plain"] == []
    assert result is not None
    assert result["recipe"]["name"] == "Pancakes"
    assert result["recipe"]["id"] is None
    assert result["recipe"]["source"] == "https://app.kitchenowl.org/recipe/42"
    assert "Flour 100 g" in result["items"]


def test_scrape_kitchenowl_unreachable_instance_returns_none(monkeypatch):
    """
    An unreachable or IP-filtered instance API must degrade to unsupported,
    not crash the scrape endpoint.
    """
    fake_manager = _FakeManager(
        default_error=requests.exceptions.ConnectionError("blocked")
    )
    monkeypatch.setattr(recipe_scraping, "request_manager", fake_manager)

    assert (
        recipe_scraping.scrapeKitchenOwl(
            "https://app.kitchenowl.org/recipe/42",
            "https://app.kitchenowl.org/api",
            42,
        )
        is None
    )


def test_scrape_kitchenowl_maps_unauthorized_to_forbidden(monkeypatch):
    fake_manager = _FakeManager()

    def send_request(method, url):
        return _FakeResponse(401, "")

    fake_manager.send_request = send_request
    monkeypatch.setattr(recipe_scraping, "request_manager", fake_manager)

    with pytest.raises(ForbiddenRequest):
        recipe_scraping.scrapeKitchenOwl(
            "https://app.kitchenowl.org/recipe/42",
            "https://app.kitchenowl.org/api",
            42,
        )


def test_scrape_kitchenowl_other_error_status_returns_none(monkeypatch):
    fake_manager = _FakeManager()

    def send_request(method, url):
        return _FakeResponse(404, "")

    fake_manager.send_request = send_request
    monkeypatch.setattr(recipe_scraping, "request_manager", fake_manager)

    assert (
        recipe_scraping.scrapeKitchenOwl(
            "https://app.kitchenowl.org/recipe/42",
            "https://app.kitchenowl.org/api",
            42,
        )
        is None
    )
