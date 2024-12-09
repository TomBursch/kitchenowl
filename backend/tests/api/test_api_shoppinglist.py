import pytest


def test_get_shopping_lists(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f'/api/household/{household_id}/shoppinglist',)
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "household_id" in data[0]
    assert data[0]["household_id"] == household_id
    assert "id" in data[0]
    assert "name" in data[0]


def test_add_item_by_name(user_client_with_household, shoppinglist_id, item_name):
    data = {"name": item_name}
    response = user_client_with_household.post(
        f'/api/shoppinglist/{shoppinglist_id}/add-item-by-name', json=data)
    assert response.status_code == 200


def test_get_items(user_client_with_household, shoppinglist_id_with_item, item_name):
    response = user_client_with_household.get(
        f'/api/shoppinglist/{shoppinglist_id_with_item}/items')
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "name" in data[0]
    assert data[0]["name"] == item_name


def test_remove_item(user_client_with_household, shoppinglist_id_with_item, item_id):
    data = {"item_id": item_id}
    response = user_client_with_household.delete(
        f'/api/shoppinglist/{shoppinglist_id_with_item}/item', json=data)
    assert response.status_code == 200
    response = user_client_with_household.get(
        f'/api/shoppinglist/{shoppinglist_id_with_item}/items')
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 0
