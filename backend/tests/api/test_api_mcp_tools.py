import pytest

from app.controller.mcp_controller import MAX_PAGE_SIZE, TOOLS


@pytest.fixture
def list_id(user_client_with_household, household_id):
    response = user_client_with_household.get(f"/api/household/{household_id}/shoppinglist")
    assert response.status_code == 200
    return response.get_json()[0]["id"]


def _rpc(client, method, params=None, id_=1):
    payload = {"jsonrpc": "2.0", "id": id_, "method": method}
    if params is not None:
        payload["params"] = params
    return client.post("/mcp", json=payload)


def _call(client, name, arguments):
    return _rpc(client, "tools/call", {"name": name, "arguments": arguments})


def _structured(res):
    body = res.get_json()
    assert "error" not in body, body
    assert not body["result"].get("isError"), body["result"]
    return body["result"]["structuredContent"]


def _tools_by_name(client):
    body = _rpc(client, "tools/list", {}).get_json()
    return {t["name"]: t for t in body["result"]["tools"]}


def test_every_tool_is_properly_described(user_client_with_household):
    tools = _tools_by_name(user_client_with_household)
    assert set(tools) == set(TOOLS)

    for name, tool in tools.items():
        description = tool["description"]
        assert not description.startswith("KitchenOwl tool:"), name
        assert len(description) > 40, f"{name} description is too thin"
        assert description.strip().endswith("."), name

        annotations = tool["annotations"]
        assert annotations["title"], name
        for hint in ("readOnlyHint", "destructiveHint", "idempotentHint", "openWorldHint"):
            assert isinstance(annotations[hint], bool), f"{name}.{hint}"
        if annotations["readOnlyHint"]:
            assert not annotations["destructiveHint"], f"{name} is both read-only and destructive"


def test_every_declared_parameter_is_described(user_client_with_household):
    for name, tool in _tools_by_name(user_client_with_household).items():
        schema = tool["inputSchema"]
        assert schema["type"] == "object", name
        for param, spec in schema["properties"].items():
            assert spec.get("description"), f"{name}.{param} has no description"
        for required in schema["required"]:
            assert required in schema["properties"], f"{name}.{required}"


def test_only_the_internet_facing_tool_is_open_world(user_client_with_household):
    tools = _tools_by_name(user_client_with_household)
    open_world = {n for n, t in tools.items() if t["annotations"]["openWorldHint"]}
    assert open_world == {"scrape_recipe"}


def test_list_tools_report_paging_metadata(user_client_with_household, household_id):
    result = _structured(
        _call(user_client_with_household, "list_recipes", {"household_id": household_id})
    )
    assert result["items"] == []
    assert result["total"] == 0
    assert result["offset"] == 0
    assert result["has_more"] is False


def test_paging_walks_a_result_set(user_client_with_household, household_id, list_id):
    for i in range(5):
        _call(
            user_client_with_household,
            "add_item_by_name",
            {"list_id": list_id, "name": f"item{i}"},
        )

    first = _structured(
        _call(
            user_client_with_household,
            "list_shoppinglist_items",
            {"list_id": list_id, "limit": 2},
        )
    )
    assert len(first["items"]) == 2
    assert first["total"] == 5
    assert first["has_more"] is True

    last = _structured(
        _call(
            user_client_with_household,
            "list_shoppinglist_items",
            {"list_id": list_id, "limit": 2, "offset": 4},
        )
    )
    assert len(last["items"]) == 1
    assert last["has_more"] is False


def test_page_size_is_capped(user_client_with_household, household_id):
    # An oversized limit must be clamped rather than honoured or rejected.
    result = _structured(
        _call(
            user_client_with_household,
            "list_items",
            {"household_id": household_id, "limit": MAX_PAGE_SIZE * 10},
        )
    )
    assert len(result["items"]) <= MAX_PAGE_SIZE


def test_recipe_lists_return_summaries_not_full_bodies(
    user_client_with_household, household_id
):
    created = _structured(
        _call(
            user_client_with_household,
            "create_recipe",
            {
                "household_id": household_id,
                "name": "Dal",
                "description": "A very long method " * 50,
                "items": ["red lentils"],
                "tags": ["vegetarian"],
            },
        )
    )

    listed = _structured(
        _call(user_client_with_household, "list_recipes", {"household_id": household_id})
    )
    summary = listed["items"][0]
    assert summary["name"] == "Dal"
    assert summary["tags"] == ["vegetarian"]
    # The bulky fields belong to get_recipe, not the listing.
    assert "description" not in summary
    assert "items" not in summary
    assert "household" not in summary

    full = _structured(
        _call(user_client_with_household, "get_recipe", {"recipe_id": created["id"]})
    )
    assert full["description"]
    assert [i["name"] for i in full["items"]] == ["red lentils"]


def test_missing_required_argument_is_a_tool_error(user_client_with_household):
    body = _call(user_client_with_household, "list_recipes", {}).get_json()
    assert "error" not in body
    assert body["result"]["isError"] is True
    assert "household_id" in body["result"]["content"][0]["text"]


def test_unknown_tool_is_a_protocol_error(user_client_with_household):
    body = _call(user_client_with_household, "no_such_tool", {}).get_json()
    assert body["error"]["code"] == -32602


def test_cross_household_access_is_denied(user_client_with_household):
    body = _call(
        user_client_with_household, "list_recipes", {"household_id": 999999}
    ).get_json()
    assert body["result"]["isError"] is True


def test_internal_errors_do_not_leak_details(user_client_with_household, household_id):
    from unittest.mock import patch

    with patch(
        "app.controller.mcp_controller._paginate_query",
        side_effect=RuntimeError("secret db internals"),
    ):
        body = _call(
            user_client_with_household, "list_recipes", {"household_id": household_id}
        ).get_json()

    text = body["result"]["content"][0]["text"]
    assert body["result"]["isError"] is True
    assert "secret db internals" not in text
