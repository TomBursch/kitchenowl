def test_recipe_creation(
    user_client_with_household,
    household_id,
    recipe_name,
    recipe_description,
    recipe_yields,
    recipe_time,
):
    """Test creating a recipe"""
    # Create a recipe
    recipe_data = {
        "name": recipe_name,
        "description": recipe_description,
        "yields": recipe_yields,
        "time": recipe_time,
        "items": [],
    }

    response = user_client_with_household.post(
        f"/api/household/{household_id}/recipe", json=recipe_data
    )
    assert response.status_code == 200
    recipe = response.get_json()
    assert "id" in recipe
    recipe_id = recipe["id"]

    # Verify recipe was created correctly
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["name"] == recipe_name
    assert recipe["description"] == recipe_description
    assert recipe["yields"] == recipe_yields
    assert recipe["time"] == recipe_time


def test_recipe_with_items(user_client_with_household, household_id, recipe_with_items):
    """Test recipe with items"""
    recipe_id = recipe_with_items

    # Get recipe and verify it has items
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert len(recipe["items"]) == 1
    assert recipe["items"][0]["description"] == "2 pieces"


def test_recipe_update(user_client_with_household, recipe_with_items):
    """Test updating a recipe"""
    recipe_id = recipe_with_items

    # Update recipe
    updated_data = {
        "name": "Updated Recipe",
        "description": "Updated description",
        "yields": 6,
        "time": 45,
        "items": [],  # Remove all items
    }

    response = user_client_with_household.post(
        f"/api/recipe/{recipe_id}", json=updated_data
    )
    assert response.status_code == 200

    # Verify updates
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200
    recipe = response.get_json()
    assert recipe["name"] == "Updated Recipe"
    assert recipe["description"] == "Updated description"
    assert recipe["yields"] == 6
    assert recipe["time"] == 45
    assert len(recipe["items"]) == 0


def test_recipe_search(user_client_with_household, household_id, recipe_with_items):
    """Test searching for recipes"""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe/search?query=Test"
    )
    assert response.status_code == 200
    recipes = response.get_json()
    assert len(recipes) > 0
    assert any(r["id"] == recipe_with_items for r in recipes)


def test_recipe_deletion(user_client_with_household, recipe_with_items):
    """Test deleting a recipe"""
    recipe_id = recipe_with_items

    # Delete recipe
    response = user_client_with_household.delete(f"/api/recipe/{recipe_id}")
    assert response.status_code == 200

    # Verify deletion
    response = user_client_with_household.get(f"/api/recipe/{recipe_id}")
    assert response.status_code != 200  # Should not be found


# --- New endpoint tests ---


def test_slim_list_omits_items_and_description(
    user_client_with_household, household_id, recipe_with_items
):
    """?details=slim omits items and description; tags are present."""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe?details=slim"
    )
    assert response.status_code == 200
    recipes = response.get_json()
    assert len(recipes) > 0
    for r in recipes:
        assert "items" not in r, "slim response must not include items"
        assert "description" not in r, "slim response must not include description"
        assert "tags" in r


def test_full_list_still_includes_items(
    user_client_with_household, household_id, recipe_with_items
):
    """Default (no ?details) response still returns full dict with items."""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe"
    )
    assert response.status_code == 200
    recipes = response.get_json()
    recipe = next(r for r in recipes if r["id"] == recipe_with_items)
    assert "items" in recipe
    assert "description" in recipe


def test_pagination_math(user_client_with_household, household_id, recipe_with_items):
    """page/per_page returns wrapped response with total and correct slice."""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe?details=slim&page=0&per_page=1"
    )
    assert response.status_code == 200
    body = response.get_json()
    assert "items" in body
    assert "total" in body
    assert body["page"] == 0
    assert body["per_page"] == 1
    assert len(body["items"]) <= 1
    assert body["total"] >= 1


def test_pagination_bad_params_returns_400(user_client_with_household, household_id):
    """Non-integer page param returns 400, not 500."""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe?page=notanint"
    )
    assert response.status_code == 400


def test_sync_endpoint_returns_required_fields(
    user_client_with_household, household_id, recipe_with_items
):
    """Sync endpoint returns recipes, deleted_ids, has_more, and server_time."""
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe/sync?updated_after=0"
    )
    assert response.status_code == 200
    body = response.get_json()
    assert "recipes" in body
    assert "deleted_ids" in body
    assert "has_more" in body
    assert "server_time" in body
    assert isinstance(body["server_time"], float)
    assert any(r["id"] == recipe_with_items for r in body["recipes"])
    assert "items" in body["recipes"][0]  # full dict, not slim


def test_sync_endpoint_delta_window(
    user_client_with_household, household_id, recipe_with_items
):
    """updated_after=<future> returns no recipes (nothing updated yet)."""
    import time
    future = int(time.time()) + 86400  # 1 day ahead
    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe/sync?updated_after={future}"
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["recipes"] == []


def test_tombstone_created_on_delete(
    user_client_with_household, household_id, recipe_with_items
):
    """Deleting a recipe creates a tombstone visible in the sync deleted_ids."""
    recipe_id = recipe_with_items
    user_client_with_household.delete(f"/api/recipe/{recipe_id}")

    response = user_client_with_household.get(
        f"/api/household/{household_id}/recipe/sync?updated_after=0"
    )
    assert response.status_code == 200
    body = response.get_json()
    assert recipe_id in body["deleted_ids"]


def test_filtered_slim_omits_items(
    user_client_with_household, household_id, recipe_with_items
):
    """POST /filter with details=slim in body must not return items."""
    tag_name = "dessert"
    user_client_with_household.post(
        f"/api/recipe/{recipe_with_items}", json={"tags": [tag_name]}
    )
    response = user_client_with_household.post(
        f"/api/household/{household_id}/recipe/filter",
        json={"filter": [tag_name], "details": "slim"},
    )
    assert response.status_code == 200
    recipes = response.get_json()
    assert len(recipes) > 0
    for r in recipes:
        assert "items" not in r, "filtered slim response must not include items"


def test_search_is_scoped_to_household(
    admin_client,
    user_client_with_household,
    household_id,
    recipe_with_items,
    recipe_name,
):
    """Cross-household search leak regression: a recipe in household A must not
    appear in a search on household B."""
    # Create a second household via admin
    response = admin_client.get("/api/user")
    assert response.status_code == 200
    admin_id = response.get_json()["id"]

    response = admin_client.post(
        "/api/household", json={"name": "other household", "member": [admin_id]}
    )
    assert response.status_code == 200
    other_household_id = response.get_json()["id"]

    # Search other household for the recipe name — must return nothing
    response = admin_client.get(
        f"/api/household/{other_household_id}/recipe/search?query={recipe_name}"
    )
    assert response.status_code == 200
    results = response.get_json()
    ids = [r["id"] for r in results]
    assert recipe_with_items not in ids, (
        "Recipe from another household leaked into search results"
    )
