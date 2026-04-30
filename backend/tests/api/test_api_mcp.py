from unittest.mock import patch


def _rpc(client, method, params=None, id_=1):
    payload = {"jsonrpc": "2.0", "id": id_, "method": method}
    if params is not None:
        payload["params"] = params
    return client.post('/mcp', json=payload)


def test_mcp_tools_list_contains_scrape_recipe(user_client_with_household):
    res = _rpc(user_client_with_household, 'tools/list', {})
    assert res.status_code == 200

    body = res.get_json()
    tools = body['result']['tools']
    names = {t['name'] for t in tools}

    assert 'scrape_recipe' in names


def test_mcp_scrape_recipe_tool_success(user_client_with_household, household_id):
    scraped = {
        'name': 'Test recipe',
        'description': 'Krok 1\nKrok 2',
        'items': [],
    }

    with patch('app.controller.mcp_controller.scrape', return_value=scraped) as mocked:
        res = _rpc(
            user_client_with_household,
            'tools/call',
            {
                'name': 'scrape_recipe',
                'arguments': {
                    'household_id': household_id,
                    'url': 'https://example.com/recipe',
                },
            },
        )

    assert res.status_code == 200
    body = res.get_json()
    assert 'error' not in body

    result = body['result']
    assert result['structuredContent'] == scraped
    mocked.assert_called_once()


def test_mcp_scrape_recipe_tool_unsupported(user_client_with_household, household_id):
    with patch('app.controller.mcp_controller.scrape', return_value=None):
        res = _rpc(
            user_client_with_household,
            'tools/call',
            {
                'name': 'scrape_recipe',
                'arguments': {
                    'household_id': household_id,
                    'url': 'https://unsupported.example',
                },
            },
        )

    assert res.status_code == 200
    body = res.get_json()
    assert 'error' in body
    assert body['error']['code'] == -32000
    assert 'Unsupported website' in body['error']['message']
