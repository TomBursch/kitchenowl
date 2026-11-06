import pytest


def test_get_shopping_lists(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
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
        f"/api/shoppinglist/{shoppinglist_id}/add-item-by-name", json=data
    )
    assert response.status_code == 200


def test_get_items(user_client_with_household, shoppinglist_id_with_item, item_name):
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "name" in data[0]
    assert data[0]["name"] == item_name


def test_remove_item(user_client_with_household, shoppinglist_id_with_item, item_id):
    data = {"item_id": item_id}
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item", json=data
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 0


def get_recent_item_names(client, shoppinglist_id):
    response = client.get(f"/api/shoppinglist/{shoppinglist_id}/recent-items")
    assert response.status_code == 200
    return [e["name"] for e in response.get_json()]


def test_remove_item_appears_in_recent_items(
    user_client_with_household, shoppinglist_id_with_item, item_id, item_name
):
    data = {"item_id": item_id}
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item", json=data
    )
    assert response.status_code == 200
    assert item_name in get_recent_item_names(
        user_client_with_household, shoppinglist_id_with_item
    )


def test_hard_remove_item(
    user_client_with_household, shoppinglist_id_with_item, item_id, item_name
):
    data = {"item_id": item_id, "hard": True}
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item", json=data
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    assert len(response.get_json()) == 0
    # hard removals are not recorded in the history
    assert item_name not in get_recent_item_names(
        user_client_with_household, shoppinglist_id_with_item
    )


def test_hard_remove_item_keeps_existing_recent_items(
    user_client_with_household, shoppinglist_id_with_item, item_id, item_name
):
    # remove the item normally, so it ends up in the recent items
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item",
        json={"item_id": item_id},
    )
    assert response.status_code == 200
    # add it again and remove it hard
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/add-item-by-name",
        json={"name": item_name},
    )
    assert response.status_code == 200
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/item",
        json={"item_id": item_id, "hard": True},
    )
    assert response.status_code == 200
    # the previously recorded recent item stays untouched
    assert item_name in get_recent_item_names(
        user_client_with_household, shoppinglist_id_with_item
    )


def test_hard_remove_items(
    user_client_with_household, shoppinglist_id_with_item, item_id, item_name
):
    # add a second item
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/add-item-by-name",
        json={"name": "Second Item"},
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    items = response.get_json()
    assert len(items) == 2

    data = {
        "items": [
            {"item_id": item_id, "hard": True},
            {
                "item_id": items[0]["id"]
                if items[0]["id"] != item_id
                else items[1]["id"]
            },
        ]
    }
    response = user_client_with_household.delete(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items", json=data
    )
    assert response.status_code == 200
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    assert len(response.get_json()) == 0
    recent_names = get_recent_item_names(
        user_client_with_household, shoppinglist_id_with_item
    )
    # the hard removed item is not recorded, the soft removed one is
    assert item_name not in recent_names
    assert "Second Item" in recent_names
