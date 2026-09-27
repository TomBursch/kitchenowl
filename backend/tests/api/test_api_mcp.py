from datetime import UTC, datetime
from unittest.mock import patch

import pytest

from app import db
from app.models import File, Item, Recipe, Tag


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


def test_mcp_tools_list_describes_recipe_discovery_controls(
    user_client_with_household,
):
    res = _rpc(user_client_with_household, 'tools/list', {})
    tools = {tool['name']: tool for tool in res.get_json()['result']['tools']}
    expected_fields = [
        'description',
        'photo',
        'photo_hash',
        'time',
        'cook_time',
        'prep_time',
        'yields',
        'source',
        'visibility',
        'created_at',
        'updated_at',
        'planned',
        'planned_days',
        'planned_cooking_dates',
        'items',
        'tags',
    ]

    for tool_name in ('list_recipes', 'search_recipes'):
        tool = tools[tool_name]
        properties = tool['inputSchema']['properties']
        assert properties['offset'] == {
            'type': 'integer',
            'minimum': 0,
            'default': 0,
        }
        assert properties['limit'] == {
            'type': 'integer',
            'minimum': 1,
            'maximum': 100,
            'default': 50,
        }
        assert properties['additional_fields'] == {
            'type': 'array',
            'items': {'type': 'string', 'enum': expected_fields},
            'uniqueItems': True,
            'default': [],
        }
        assert 'additional_fields' in tool['description']
        assert 'get_recipe' in tool['description']


def test_mcp_recipe_discovery_classifies_every_recipe_model_field(
    user_client_with_household,
):
    res = _rpc(user_client_with_household, 'tools/list', {})
    tools = {tool['name']: tool for tool in res.get_json()['result']['tools']}
    additional_fields = set(
        tools['list_recipes']['inputSchema']['properties']['additional_fields'][
            'items'
        ]['enum']
    )
    always_returned_fields = {'id', 'name'}
    deliberately_excluded_fields = {
        'household_id',
        'server_curated',
        'server_scrapes',
        'suggestion_score',
        'suggestion_rank',
    }
    computed_and_relationship_fields = {
        'photo_hash',
        'planned',
        'planned_days',
        'planned_cooking_dates',
        'items',
        'tags',
    }
    model_fields = set(Recipe.get_column_names())

    unclassified_fields = model_fields.difference(
        always_returned_fields,
        deliberately_excluded_fields,
        additional_fields,
    )
    assert not unclassified_fields, (
        'New Recipe fields must be added to the MCP additional-fields allowlist '
        f'or deliberately excluded: {sorted(unclassified_fields)}'
    )
    assert model_fields == (
        always_returned_fields
        | deliberately_excluded_fields
        | additional_fields.difference(computed_and_relationship_fields)
    )
    assert additional_fields.difference(model_fields) == (
        computed_and_relationship_fields
    )


def test_mcp_list_recipes_returns_compact_references_by_default(
    user_client_with_household,
    household_id,
    recipe_with_items,
    recipe_name,
):
    res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {'household_id': household_id},
        },
    )

    assert res.status_code == 200
    body = res.get_json()
    assert 'error' not in body
    assert body['result']['structuredContent'] == {
        'items': [{'id': recipe_with_items, 'name': recipe_name}],
        'total': 1,
        'next_offset': None,
    }


def test_mcp_list_recipes_paginates_with_fifty_item_default(
    user_client_with_household,
    household_id,
):
    recipes = [
        Recipe(name=f'Recipe {index:03}', description='', household_id=household_id)
        for index in range(52)
    ]
    db.session.add_all(recipes)
    db.session.commit()

    first_res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {'household_id': household_id},
        },
    )
    first = first_res.get_json()['result']['structuredContent']

    assert first['total'] == 52
    assert len(first['items']) == 50
    assert first['items'][0]['name'] == 'Recipe 000'
    assert first['items'][-1]['name'] == 'Recipe 049'
    assert first['next_offset'] == 50

    second_res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {'household_id': household_id, 'offset': 50},
        },
    )
    second = second_res.get_json()['result']['structuredContent']

    assert [item['name'] for item in second['items']] == [
        'Recipe 050',
        'Recipe 051',
    ]
    assert second['total'] == 52
    assert second['next_offset'] is None


def test_mcp_list_recipes_returns_only_requested_fields(
    user_client_with_household,
    household_id,
    recipe_with_items,
    recipe_name,
    recipe_description,
    recipe_time,
    recipe_yields,
    item_name,
):
    add_tag_res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'add_recipe_tag',
            'arguments': {'recipe_id': recipe_with_items, 'name': 'Quick'},
        },
    )
    assert 'error' not in add_tag_res.get_json()
    item = Item.find_by_name(household_id, item_name)
    tag = Tag.find_by_name(household_id, 'Quick')

    res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {
                'household_id': household_id,
                'additional_fields': [
                    'description',
                    'time',
                    'yields',
                    'items',
                    'tags',
                ],
            },
        },
    )

    assert res.status_code == 200
    body = res.get_json()
    assert 'error' not in body
    assert body['result']['structuredContent']['items'] == [
        {
            'id': recipe_with_items,
            'name': recipe_name,
            'description': recipe_description,
            'time': recipe_time,
            'yields': recipe_yields,
            'items': [
                {
                    'id': item.id,
                    'name': item_name,
                    'description': '2 pieces',
                    'optional': True,
                }
            ],
            'tags': [{'id': tag.id, 'name': 'Quick'}],
        }
    ]


def test_mcp_list_recipes_supports_all_user_facing_scalar_and_computed_fields(
    user_client_with_household,
    household_id,
    planned_recipe,
    recipe_name,
    recipe_description,
    recipe_time,
    recipe_yields,
):
    recipe = Recipe.find_by_id(planned_recipe)
    recipe.photo = 'recipe.jpg'
    recipe.cook_time = 20
    recipe.prep_time = 10
    recipe.source = 'https://example.com/recipe'
    db.session.add(File(filename='recipe.jpg', blur_hash='test-blur-hash'))
    db.session.add(recipe)
    db.session.commit()

    additional_fields = [
        'description',
        'photo',
        'photo_hash',
        'time',
        'cook_time',
        'prep_time',
        'yields',
        'source',
        'visibility',
        'created_at',
        'updated_at',
        'planned',
        'planned_days',
        'planned_cooking_dates',
    ]
    res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {
                'household_id': household_id,
                'additional_fields': additional_fields,
            },
        },
    )

    assert res.status_code == 200
    body = res.get_json()
    assert 'error' not in body
    item = body['result']['structuredContent']['items'][0]
    assert set(item) == {'id', 'name', *additional_fields}
    assert item | {'created_at': None, 'updated_at': None} == {
        'id': planned_recipe,
        'name': recipe_name,
        'description': recipe_description,
        'photo': 'recipe.jpg',
        'photo_hash': 'test-blur-hash',
        'time': recipe_time,
        'cook_time': 20,
        'prep_time': 10,
        'yields': recipe_yields,
        'source': 'https://example.com/recipe',
        'visibility': 0,
        'created_at': None,
        'updated_at': None,
        'planned': True,
        'planned_days': [
            datetime.fromtimestamp(
                pytest.FIX_DATETIME / 1000,
                UTC,
            ).weekday()
        ],
        'planned_cooking_dates': [pytest.FIX_DATETIME],
    }
    assert isinstance(item['created_at'], int)
    assert isinstance(item['updated_at'], int)


def test_mcp_search_recipes_uses_compact_paginated_field_selection(
    user_client_with_household,
    household_id,
):
    db.session.add_all(
        [
            Recipe(name='Alpha soup', description='Alpha instructions', household_id=household_id),
            Recipe(name='Beta soup', description='Beta instructions', household_id=household_id),
            Recipe(name='Chocolate cake', description='Cake instructions', household_id=household_id),
        ]
    )
    db.session.commit()

    first_res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'search_recipes',
            'arguments': {
                'household_id': household_id,
                'query': 'soup',
                'limit': 1,
                'additional_fields': ['description'],
            },
        },
    )
    first = first_res.get_json()['result']['structuredContent']

    assert first == {
        'items': [
            {
                'id': 1,
                'name': 'Alpha soup',
                'description': 'Alpha instructions',
            }
        ],
        'total': 2,
        'next_offset': 1,
    }

    second_res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'search_recipes',
            'arguments': {
                'household_id': household_id,
                'query': 'soup',
                'offset': 1,
                'limit': 1,
            },
        },
    )
    second = second_res.get_json()['result']['structuredContent']

    assert second == {
        'items': [{'id': 2, 'name': 'Beta soup'}],
        'total': 2,
        'next_offset': None,
    }


@pytest.mark.parametrize(
    ('arguments', 'message'),
    [
        ({'offset': -1}, 'offset must be non-negative'),
        ({'limit': 0}, 'limit must be between 1 and 100'),
        ({'limit': 101}, 'limit must be between 1 and 100'),
        (
            {'additional_fields': 'description'},
            'additional_fields must be an array of strings',
        ),
        (
            {'additional_fields': ''},
            'additional_fields must be an array of strings',
        ),
        (
            {'additional_fields': ['description', 'description']},
            'additional_fields must not contain duplicates',
        ),
        (
            {'additional_fields': ['server_scrapes']},
            'Unsupported additional_fields: server_scrapes',
        ),
    ],
)
def test_mcp_recipe_discovery_rejects_invalid_pagination_and_fields(
    user_client_with_household,
    household_id,
    arguments,
    message,
):
    res = _rpc(
        user_client_with_household,
        'tools/call',
        {
            'name': 'list_recipes',
            'arguments': {'household_id': household_id} | arguments,
        },
    )

    assert res.status_code == 200
    body = res.get_json()
    assert body['error']['code'] == -32000
    assert body['error']['message'] == message


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
