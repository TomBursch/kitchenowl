from __future__ import annotations

import logging
import time
import uuid
from typing import Any

from flask import Blueprint, Response, jsonify, request, stream_with_context
from flask_jwt_extended import jwt_required

from app import db
from app.config import BACKEND_VERSION
from app.errors import ForbiddenRequest, InvalidUsage, NotFoundRequest
from app.helpers.safe_error import safe_error_message
from app.service.agent_tools import TOOLS

mcp = Blueprint("mcp", __name__)

_logger = logging.getLogger(__name__)
# Exception types whose message is intentionally user-facing and safe to send
# back to the MCP client. Anything else is logged server-side and replaced by
# a generic error to avoid leaking internal details.
_SAFE_EXCEPTIONS = (InvalidUsage, NotFoundRequest, ForbiddenRequest, ValueError)


def _jsonrpc_ok(id_value: Any, result: Any):
    return jsonify({"jsonrpc": "2.0", "id": id_value, "result": result})


def _jsonrpc_err(id_value: Any, code: int, message: str):
    return jsonify(
        {
            "jsonrpc": "2.0",
            "id": id_value,
            "error": {"code": code, "message": message},
        }
    )


def _as_tool_result(payload: Any):
    import json

    text = json.dumps(payload, ensure_ascii=False, default=str)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": payload,
    }


def _handle_jsonrpc(body: dict[str, Any]):
    id_value = body.get("id")
    method = body.get("method")
    params = body.get("params") or {}

    try:
        if method == "initialize":
            return _jsonrpc_ok(
                id_value,
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {
                        "name": "kitchenowl-mcp",
                        "version": str(BACKEND_VERSION),
                    },
                },
            )

        if method == "notifications/initialized":
            return ("", 204)

        if method == "ping":
            return _jsonrpc_ok(id_value, {})

        if method == "tools/list":
            tools = []
            for name, (schema, _) in TOOLS.items():
                tools.append(
                    {
                        "name": name,
                        "description": f"KitchenOwl tool: {name}",
                        "inputSchema": schema,
                    }
                )
            return _jsonrpc_ok(id_value, {"tools": tools})

        if method == "tools/call":
            name = params.get("name")
            args = params.get("arguments") or {}
            if name not in TOOLS:
                return _jsonrpc_err(id_value, -32601, f"Unknown tool: {name}")
            _, handler = TOOLS[name]
            result = handler(args)
            db.session.commit()
            return _jsonrpc_ok(id_value, _as_tool_result(result))

        return _jsonrpc_err(id_value, -32601, f"Method not found: {method}")
    except _SAFE_EXCEPTIONS as e:
        db.session.rollback()
        return _jsonrpc_err(id_value, -32000, safe_error_message(e, type(e).__name__))
    except Exception:
        db.session.rollback()
        # Avoid leaking internal exception details to MCP clients; log on the
        # server instead.
        _logger.exception("MCP request failed: method=%s", method)
        return _jsonrpc_err(id_value, -32000, "Internal error")


@mcp.route("", methods=["GET"])
@mcp.route("/sse", methods=["GET"])
@jwt_required()
def mcp_sse():
    session_id = str(uuid.uuid4())

    def generate():
        endpoint = request.url_root.rstrip("/") + f"/mcp/messages/{session_id}"
        yield f"event: endpoint\ndata: {endpoint}\n\n"
        while True:
            yield "event: ping\ndata: {}\n\n"
            time.sleep(15)

    return Response(
        stream_with_context(generate()),
        mimetype="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@mcp.route("", methods=["POST"])
@jwt_required()
def mcp_post():
    body = request.get_json(silent=True) or {}
    return _handle_jsonrpc(body)


@mcp.route("/messages", methods=["POST"])
@mcp.route("/messages/<session_id>", methods=["POST"])
@jwt_required()
def mcp_messages(session_id: str | None = None):
    body = request.get_json(silent=True) or {}
    return _handle_jsonrpc(body)
