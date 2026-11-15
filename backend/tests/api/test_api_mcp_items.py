import pytest

from app.models import Category, Household, Item


def _call(client, name, arguments):
    res = client.post(
        '/mcp',
        json={
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'tools/call',
            'params': {'name': name, 'arguments': arguments},
        },
    )
    assert res.status_code == 200
    return res.get_json()


def _result(body):
    assert 'error' not in body, body
    return body['result']['structuredContent']


@pytest.fixture
def category_id(user_client_with_household, household_id):
    res = user_client_with_household.post(
        f'/api/household/{household_id}/category', json={'name': '🥬 Fruits'}
    )
    assert res.status_code == 200
    return res.get_json()['id']


@pytest.fixture
def foreign_household():
    household = Household(name='Other household').save()
    category = Category.create_by_name(household.id, 'Foreign category')
    item = Item.create_by_name(household.id, 'foreign item')
    return {'id': household.id, 'category_id': category.id, 'item_id': item.id}


def test_mcp_tools_list_contains_item_category_tools(user_client_with_household):
    res = user_client_with_household.post(
        '/mcp', json={'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'}
    )
    tools = {t['name']: t for t in res.get_json()['result']['tools']}

    for name in ('list_categories', 'create_category', 'list_item_icons', 'update_item'):
        assert name in tools
    assert 'list_item_icons' in tools['update_item']['description']


def test_mcp_list_categories(user_client_with_household, household_id, category_id):
    items = _result(
        _call(user_client_with_household, 'list_categories', {'household_id': household_id})
    )['items']

    category = next(c for c in items if c['id'] == category_id)
    assert category['name'] == '🥬 Fruits'
    assert {'id', 'name', 'default_key', 'ordering'} <= category.keys()


def test_mcp_create_category_is_idempotent(user_client_with_household, household_id):
    args = {'household_id': household_id, 'name': ' Bakery '}
    first = _result(_call(user_client_with_household, 'create_category', args))
    second = _result(_call(user_client_with_household, 'create_category', args))

    assert first['name'] == 'Bakery'
    assert first['id'] == second['id']

    lower = _result(
        _call(
            user_client_with_household,
            'create_category',
            {'household_id': household_id, 'name': 'bakery'},
        )
    )
    assert lower['id'] == first['id']

    empty = _result(
        _call(
            user_client_with_household,
            'create_category',
            {'household_id': household_id, 'name': '  '},
        )
    )
    assert empty == {'created': False, 'reason': 'empty_name'}


def test_mcp_category_tools_reject_foreign_household(
    user_client_with_household, foreign_household
):
    for name, args in (
        ('list_categories', {'household_id': foreign_household['id']}),
        ('create_category', {'household_id': foreign_household['id'], 'name': 'x'}),
    ):
        body = _call(user_client_with_household, name, args)
        assert body['error']['code'] == -32000


def test_mcp_list_item_icons(user_client_with_household):
    everything = _result(_call(user_client_with_household, 'list_item_icons', {}))['items']
    assert 'mushroom' in everything
    assert len(everything) > 300

    tomatoes = _result(
        _call(user_client_with_household, 'list_item_icons', {'search': 'Tomato'})
    )['items']
    assert tomatoes
    assert all('tomato' in icon for icon in tomatoes)


def test_mcp_update_item_sets_icon_and_category(
    user_client_with_household, item_id, category_id
):
    item = _result(
        _call(
            user_client_with_household,
            'update_item',
            {'item_id': item_id, 'icon': 'mushroom', 'category_id': category_id},
        )
    )

    assert item['icon'] == 'mushroom'
    assert item['category_id'] == category_id
    assert item['category']['name'] == '🥬 Fruits'

    # Same state as the REST API reports
    rest = user_client_with_household.get(f'/api/item/{item_id}').get_json()
    assert rest['icon'] == 'mushroom'
    assert rest['category_id'] == category_id


def test_mcp_update_item_by_category_name_ignores_case(
    user_client_with_household, item_id, category_id
):
    item = _result(
        _call(
            user_client_with_household,
            'update_item',
            {'item_id': item_id, 'category_name': '🥬 fruits'},
        )
    )
    assert item['category_id'] == category_id


def test_mcp_update_item_removes_category_and_icon(
    user_client_with_household, item_id, category_id
):
    _call(
        user_client_with_household,
        'update_item',
        {'item_id': item_id, 'icon': 'apple', 'category_id': category_id},
    )

    item = _result(
        _call(
            user_client_with_household,
            'update_item',
            {'item_id': item_id, 'icon': None, 'category_id': None},
        )
    )
    assert item['icon'] is None
    assert item['category_id'] is None
    assert 'category' not in item


def test_mcp_update_item_leaves_omitted_fields(
    user_client_with_household, item_id, category_id
):
    _call(
        user_client_with_household,
        'update_item',
        {'item_id': item_id, 'icon': 'apple', 'category_id': category_id},
    )
    item = _result(
        _call(user_client_with_household, 'update_item', {'item_id': item_id, 'name': 'Apples'})
    )

    assert item['name'] == 'Apples'
    assert item['icon'] == 'apple'
    assert item['category_id'] == category_id


def test_mcp_update_item_renames_with_case_change(user_client_with_household, item_id):
    _call(user_client_with_household, 'update_item', {'item_id': item_id, 'name': 'apples'})
    item = _result(
        _call(user_client_with_household, 'update_item', {'item_id': item_id, 'name': 'Apples'})
    )
    assert item['name'] == 'Apples'


def test_mcp_update_item_rejects_unknown_icon_without_changes(
    user_client_with_household, item_id, category_id
):
    result = _result(
        _call(
            user_client_with_household,
            'update_item',
            {'item_id': item_id, 'icon': 'mushrooms', 'category_id': category_id},
        )
    )

    assert result['updated'] is False
    assert result['reason'] == 'unknown_icon'
    assert 'mushroom' in result['suggestions']

    rest = user_client_with_household.get(f'/api/item/{item_id}').get_json()
    assert rest['icon'] is None
    assert rest['category_id'] is None


def test_mcp_update_item_rejects_unknown_category_name(
    user_client_with_household, item_id, category_id
):
    result = _result(
        _call(
            user_client_with_household,
            'update_item',
            {'item_id': item_id, 'category_name': 'Fruits'},
        )
    )
    assert result['reason'] == 'category_not_found'
    assert '🥬 Fruits' in result['categories']


def test_mcp_update_item_rejects_both_category_arguments(
    user_client_with_household, item_id, category_id
):
    body = _call(
        user_client_with_household,
        'update_item',
        {'item_id': item_id, 'category_id': category_id, 'category_name': '🥬 Fruits'},
    )
    assert body['error']['code'] == -32000


def test_mcp_update_item_rejects_taken_name(
    user_client_with_household, household_id, item_id
):
    other = Item.create_by_name(household_id, 'Bread')

    result = _result(
        _call(user_client_with_household, 'update_item', {'item_id': item_id, 'name': 'bread'})
    )
    assert result == {
        'updated': False,
        'reason': 'name_taken',
        'existing_item_id': other.id,
    }


def test_mcp_update_item_rejects_foreign_category(
    user_client_with_household, item_id, foreign_household
):
    body = _call(
        user_client_with_household,
        'update_item',
        {'item_id': item_id, 'category_id': foreign_household['category_id']},
    )
    assert body['error']['code'] == -32000
    assert "item's household" in body['error']['message']


def test_mcp_update_item_rejects_foreign_item(
    user_client_with_household, foreign_household
):
    body = _call(
        user_client_with_household,
        'update_item',
        {'item_id': foreign_household['item_id'], 'icon': 'apple'},
    )
    assert body['error']['code'] == -32000
    assert Item.find_by_id(foreign_household['item_id']).icon is None
