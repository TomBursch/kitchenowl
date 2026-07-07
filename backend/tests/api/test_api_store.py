import pytest


def create_store(client, household_id, name):
    response = client.post(
        f"/api/household/{household_id}/store", json={"name": name}
    )
    assert response.status_code == 200
    data = response.get_json()
    assert "id" in data
    assert data["name"] == name
    return data["id"]


def create_item(client, household_id, name, store_ids=None):
    body = {"name": name}
    if store_ids is not None:
        body["store_ids"] = store_ids
    response = client.post(f"/api/household/{household_id}/item", json=body)
    assert response.status_code == 200
    return response.get_json()


def test_add_and_list_stores(user_client_with_household, household_id):
    create_store(user_client_with_household, household_id, "Store A")
    create_store(user_client_with_household, household_id, "Store B")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/store"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 2
    assert {e["name"] for e in data} == {"Store A", "Store B"}


def test_rename_store(user_client_with_household, household_id):
    store_id = create_store(user_client_with_household, household_id, "Store A")

    response = user_client_with_household.post(
        f"/api/store/{store_id}", json={"name": "Renamed Store"}
    )
    assert response.status_code == 200
    assert response.get_json()["name"] == "Renamed Store"


def test_delete_store(user_client_with_household, household_id):
    store_id = create_store(user_client_with_household, household_id, "Store A")

    response = user_client_with_household.delete(f"/api/store/{store_id}")
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/store"
    )
    assert response.get_json() == []


def test_item_with_store_ids(user_client_with_household, household_id):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    store_b = create_store(user_client_with_household, household_id, "Store B")

    item = create_item(
        user_client_with_household,
        household_id,
        "Cheese",
        store_ids=[store_a, store_b],
    )
    assert "stores" in item
    assert {s["id"] for s in item["stores"]} == {store_a, store_b}

    response = user_client_with_household.get(f"/api/item/{item['id']}")
    assert response.status_code == 200
    data = response.get_json()
    assert {s["id"] for s in data["stores"]} == {store_a, store_b}


def test_update_item_store_ids_replaces_full_set(
    user_client_with_household, household_id
):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    store_b = create_store(user_client_with_household, household_id, "Store B")

    item = create_item(
        user_client_with_household, household_id, "Cheese", store_ids=[store_a]
    )

    response = user_client_with_household.post(
        f"/api/item/{item['id']}", json={"store_ids": [store_b]}
    )
    assert response.status_code == 200
    data = response.get_json()
    assert {s["id"] for s in data["stores"]} == {store_b}

    response = user_client_with_household.post(
        f"/api/item/{item['id']}", json={"store_ids": []}
    )
    assert response.status_code == 200
    assert "stores" not in response.get_json()


def test_merge_stores_dedups_item_assignments(
    user_client_with_household, household_id
):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    store_b = create_store(user_client_with_household, household_id, "Store B")

    item1 = create_item(
        user_client_with_household, household_id, "Cheese", store_ids=[store_a]
    )
    item2 = create_item(
        user_client_with_household,
        household_id,
        "Milk",
        store_ids=[store_a, store_b],
    )

    # merge store_b into store_a
    response = user_client_with_household.post(
        f"/api/store/{store_a}", json={"merge_store_id": store_b}
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/store"
    )
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["id"] == store_a

    response = user_client_with_household.get(f"/api/item/{item1['id']}")
    assert {s["id"] for s in response.get_json()["stores"]} == {store_a}

    response = user_client_with_household.get(f"/api/item/{item2['id']}")
    assert {s["id"] for s in response.get_json()["stores"]} == {store_a}


def test_merge_items_dedups_stores(user_client_with_household, household_id):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    store_b = create_store(user_client_with_household, household_id, "Store B")

    item1 = create_item(
        user_client_with_household, household_id, "Cheese", store_ids=[store_a]
    )
    item2 = create_item(
        user_client_with_household,
        household_id,
        "Fromage",
        store_ids=[store_a, store_b],
    )

    response = user_client_with_household.post(
        f"/api/item/{item1['id']}", json={"merge_item_id": item2["id"]}
    )
    assert response.status_code == 200
    data = response.get_json()
    assert {s["id"] for s in data["stores"]} == {store_a, store_b}


def test_export_import_round_trips_stores(user_client_with_household, household_id):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    create_item(
        user_client_with_household, household_id, "Cheese", store_ids=[store_a]
    )

    response = user_client_with_household.get(
        f"/api/household/{household_id}/export/items"
    )
    assert response.status_code == 200
    exported = response.get_json()["items"]
    cheese = next(e for e in exported if e["name"] == "Cheese")
    assert cheese["stores"] == ["Store A"]

    response = user_client_with_household.post(
        f"/api/household/{household_id}/import", json={"items": exported}
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/store"
    )
    assert len(response.get_json()) == 1

    response = user_client_with_household.get(
        f"/api/household/{household_id}/item"
    )
    cheese_after = next(e for e in response.get_json() if e["name"] == "Cheese")
    assert {s["name"] for s in cheese_after["stores"]} == {"Store A"}


def test_import_does_not_override_existing_stores(
    user_client_with_household, household_id
):
    store_a = create_store(user_client_with_household, household_id, "Store A")
    create_store(user_client_with_household, household_id, "Store B")
    create_item(
        user_client_with_household, household_id, "Cheese", store_ids=[store_a]
    )

    response = user_client_with_household.post(
        f"/api/household/{household_id}/import",
        json={"items": [{"name": "Cheese", "stores": ["Store B"]}]},
    )
    assert response.status_code == 200

    response = user_client_with_household.get(
        f"/api/household/{household_id}/item"
    )
    cheese = next(e for e in response.get_json() if e["name"] == "Cheese")
    assert {s["name"] for s in cheese["stores"]} == {"Store A"}
