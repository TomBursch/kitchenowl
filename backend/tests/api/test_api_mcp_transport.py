import json

import pytest

from app.controller.mcp_controller import (
    LATEST_PROTOCOL_VERSION,
    SUPPORTED_PROTOCOL_VERSIONS,
    _SseSession,
    _sse_sessions,
)


def _rpc(client, method, params=None, id_=1):
    payload = {"jsonrpc": "2.0", "id": id_, "method": method}
    if params is not None:
        payload["params"] = params
    return client.post("/mcp", json=payload)


def _read_sse_events(response, count):
    # Pulls `count` (event, data) pairs off a streamed response, skipping
    # keep-alive comments.
    events = []
    buffer = ""
    for chunk in response.response:
        buffer += chunk.decode()
        while "\n\n" in buffer:
            raw, buffer = buffer.split("\n\n", 1)
            event, data = None, None
            for line in raw.splitlines():
                if line.startswith("event:"):
                    event = line[len("event:"):].strip()
                elif line.startswith("data:"):
                    data = line[len("data:"):].strip()
            if event is not None:
                events.append((event, data))
            if len(events) >= count:
                return events
    return events


def test_initialize_echoes_supported_protocol_version(user_client_with_household):
    for version in SUPPORTED_PROTOCOL_VERSIONS:
        res = _rpc(user_client_with_household, "initialize", {"protocolVersion": version})
        assert res.status_code == 200
        assert res.get_json()["result"]["protocolVersion"] == version


def test_initialize_falls_back_to_latest_for_unknown_version(user_client_with_household):
    res = _rpc(user_client_with_household, "initialize", {"protocolVersion": "1999-01-01"})
    assert res.get_json()["result"]["protocolVersion"] == LATEST_PROTOCOL_VERSION


def test_initialize_reports_server_info_and_instructions(user_client_with_household):
    result = _rpc(user_client_with_household, "initialize", {}).get_json()["result"]
    assert result["serverInfo"]["name"] == "kitchenowl-mcp"
    assert result["capabilities"]["tools"] is not None
    assert result["instructions"]


def test_notifications_get_202_and_no_body(user_client_with_household):
    res = user_client_with_household.post(
        "/mcp", json={"jsonrpc": "2.0", "method": "notifications/initialized"}
    )
    assert res.status_code == 202
    assert res.data == b""


def test_ping_roundtrip(user_client_with_household):
    body = _rpc(user_client_with_household, "ping").get_json()
    assert body["result"] == {}
    assert body["id"] == 1


def test_unknown_method_is_a_protocol_error(user_client_with_household):
    body = _rpc(user_client_with_household, "does/not/exist").get_json()
    assert body["error"]["code"] == -32601


def test_batch_request_returns_one_response_per_request(user_client_with_household):
    res = user_client_with_household.post(
        "/mcp",
        json=[
            {"jsonrpc": "2.0", "id": 1, "method": "ping"},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "ping"},
        ],
    )
    body = res.get_json()
    assert isinstance(body, list)
    # The notification must not produce a response.
    assert [r["id"] for r in body] == [1, 2]


def test_malformed_body_is_an_invalid_request(user_client_with_household):
    body = user_client_with_household.post("/mcp", json="not-an-object").get_json()
    assert body["error"]["code"] == -32600


def test_get_and_delete_on_root_are_405(user_client_with_household):
    for method in ("get", "delete"):
        res = getattr(user_client_with_household, method)("/mcp")
        assert res.status_code == 405
        assert res.headers["Allow"] == "POST"


def test_transport_requires_authentication(client):
    res = client.post("/mcp", json={"jsonrpc": "2.0", "id": 1, "method": "ping"})
    assert res.status_code == 401


@pytest.fixture
def sse_session(user_client_with_household):
    _sse_sessions.clear()
    res = user_client_with_household.get("/mcp/sse")
    assert res.status_code == 200
    assert res.mimetype == "text/event-stream"

    (event, data), = _read_sse_events(res, 1)
    assert event == "endpoint"

    yield data, data.split("session_id=")[1], res
    res.close()
    _sse_sessions.clear()


def test_sse_announces_a_relative_endpoint(sse_session):
    endpoint, session_id, _ = sse_session
    assert endpoint.startswith("/mcp/messages?session_id=")
    assert session_id in _sse_sessions


def test_sse_post_is_accepted_and_reply_arrives_on_the_stream(
    sse_session, user_client_with_household
):
    endpoint, _, stream = sse_session

    res = user_client_with_household.post(
        endpoint, json={"jsonrpc": "2.0", "id": 7, "method": "ping"}
    )
    assert res.status_code == 202
    assert res.data == b""

    (event, data), = _read_sse_events(stream, 1)
    assert event == "message"
    assert json.loads(data) == {"jsonrpc": "2.0", "id": 7, "result": {}}


def test_sse_notification_produces_no_stream_message(
    sse_session, user_client_with_household
):
    endpoint, session_id, _ = sse_session

    res = user_client_with_household.post(
        endpoint, json={"jsonrpc": "2.0", "method": "notifications/initialized"}
    )
    assert res.status_code == 202
    assert _sse_sessions[session_id].outbox.empty()


def test_post_to_unknown_session_is_404(user_client_with_household):
    res = user_client_with_household.post(
        "/mcp/messages?session_id=nope", json={"jsonrpc": "2.0", "id": 1, "method": "ping"}
    )
    assert res.status_code == 404


def test_post_without_session_id_is_404(user_client_with_household):
    res = user_client_with_household.post(
        "/mcp/messages", json={"jsonrpc": "2.0", "id": 1, "method": "ping"}
    )
    assert res.status_code == 404


def test_cannot_push_into_another_users_session(user_client_with_household):
    _sse_sessions.clear()
    foreign = _SseSession(user_id=99999)
    _sse_sessions[foreign.id] = foreign

    res = user_client_with_household.post(
        f"/mcp/messages?session_id={foreign.id}",
        json={"jsonrpc": "2.0", "id": 1, "method": "ping"},
    )
    assert res.status_code == 403
    assert foreign.outbox.empty()
    _sse_sessions.clear()
