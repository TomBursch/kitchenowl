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


def test_shoppinglist_locations(user_client_with_household, household_id):
    response = user_client_with_household.post(
        f"/api/household/{household_id}/shoppinglist",
        json={
            "name": "Hardware store",
            "locations": [
                {"name": "Store A", "latitude": 48.137, "longitude": 11.575},
                {"latitude": 48.2, "longitude": 11.6, "radius": 300},
            ],
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data["locations"]) == 2
    assert data["locations"][0]["name"] == "Store A"
    assert data["locations"][0]["radius"] == 150
    assert data["locations"][1]["name"] is None
    assert data["locations"][1]["radius"] == 300
    shoppinglist_id = data["id"]

    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}",
        json={
            "locations": [{"name": "Store B", "latitude": -33.86, "longitude": 151.2}]
        },
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "Hardware store"
    assert len(data["locations"]) == 1
    assert data["locations"][0]["name"] == "Store B"

    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    lists = {s["id"]: s for s in response.get_json()}
    assert len(lists[shoppinglist_id]["locations"]) == 1

    # Renaming keeps locations
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}", json={"name": "DIY"}
    )
    assert len(response.get_json()["locations"]) == 1

    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}", json={"locations": []}
    )
    assert response.get_json()["locations"] == []

    # Deleting a list with locations works
    user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}",
        json={"locations": [{"latitude": 1, "longitude": 1}]},
    )
    response = user_client_with_household.delete(f"/api/shoppinglist/{shoppinglist_id}")
    assert response.status_code == 200


@pytest.mark.parametrize(
    "location",
    [
        {"latitude": 91, "longitude": 0},
        {"latitude": 0, "longitude": -181},
        {"latitude": 0, "longitude": 0, "radius": 10},
        {"longitude": 0},
    ],
)
def test_shoppinglist_locations_invalid(
    user_client_with_household, shoppinglist_id, location
):
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}", json={"locations": [location]}
    )
    assert response.status_code == 400
