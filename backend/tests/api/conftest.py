import pytest
from app import app, db
from unittest.mock import patch
from datetime import datetime, timedelta, timezone


@pytest.fixture
def client():
    app_context = app.app_context()
    app_context.push()
    app.config["TESTING"] = True
    db.create_all()
    client = app.test_client()
    yield client
    db.session.rollback()
    db.drop_all()
    app_context.pop()


@pytest.fixture
def username():
    return "testuser"


@pytest.fixture
def name():
    return "testname"


@pytest.fixture
def password():
    return "testpwd"


@pytest.fixture
def admin_username():
    return "testadmin"


@pytest.fixture
def admin_name():
    return "adminname"


@pytest.fixture
def admin_password():
    return "adminpwd"


@pytest.fixture
def household_name():
    return "testhousehold"


@pytest.fixture
def item_name():
    return "testitem"


@pytest.fixture
def recipe_name():
    return "Test Recipe"


@pytest.fixture
def recipe_description():
    return "A test recipe description"


@pytest.fixture
def recipe_yields():
    return 4


@pytest.fixture
def recipe_time():
    return 30

FIX_DATETIME = int((datetime.now(timezone.utc).replace(hour=23,minute=59, second=59, microsecond=0).replace(tzinfo=None) + timedelta(days=2)).timestamp() * 1000)

def pytest_configure():
    pytest.FIX_DATETIME = FIX_DATETIME

FIX_DATETIME = int(
    (
        datetime.now(timezone.utc)
        .replace(hour=23, minute=59, second=59, microsecond=0)
        .replace(tzinfo=None)
        + timedelta(days=2)
    ).timestamp()
    * 1000
)


def pytest_configure():
    pytest.FIX_DATETIME = FIX_DATETIME


@pytest.fixture
def onboarded_client(client, admin_username, admin_name, admin_password):
    onboard_data = {
        "username": admin_username,
        "name": admin_name,
        "password": admin_password,
    }
    response = client.post("/api/onboarding", json=onboard_data)
    return client


@pytest.fixture
def admin_client(client, admin_username, admin_name, admin_password):
    onboard_data = {
        "username": admin_username,
        "name": admin_name,
        "password": admin_password,
    }
    response = client.post("/api/onboarding", json=onboard_data)
    assert response.status_code == 200, (
        f"Failed to onboard admin: {response.get_json()}"
    )
    data = response.get_json()
    assert "access_token" in data, f"No access token in response: {data}"
    client.environ_base["HTTP_AUTHORIZATION"] = f"Bearer {data['access_token']}"
    return client


@pytest.fixture
def user_client(admin_client, username, name, password):
    data = {"username": username, "name": name, "password": password}
    response = admin_client.post("/api/user/new", json=data)
    assert response.status_code == 200, f"Failed to create user: {response.get_json()}"
    data = {"username": username, "password": password}
    response = admin_client.post("/api/auth", json=data)
    assert response.status_code == 200, f"Failed to login: {response.get_json()}"
    data = response.get_json()
    admin_client.environ_base["HTTP_AUTHORIZATION"] = f"Bearer {data['access_token']}"
    return admin_client


@pytest.fixture
def user_client_with_household(user_client, household_name):
    response = user_client.get(
        "/api/user",
    )
    assert response.status_code == 200
    data = response.get_json()
    user_id = data["id"]
    data = {"name": household_name, "member": [user_id]}
    response = user_client.post("/api/household", json=data)
    return user_client


@pytest.fixture
def household_id(user_client_with_household):
    response = user_client_with_household.get(
        "/api/household",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "id" in data[0]
    return data[0]["id"]


@pytest.fixture
def shoppinglist_id(user_client_with_household, household_id):
    response = user_client_with_household.get(
        f"/api/household/{household_id}/shoppinglist",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "id" in data[0]
    return data[0]["id"]


@pytest.fixture
def shoppinglist_id_with_item(user_client_with_household, shoppinglist_id, item_name):
    data = {"name": item_name}
    response = user_client_with_household.post(
        f"/api/shoppinglist/{shoppinglist_id}/add-item-by-name", json=data
    )
    assert response.status_code == 200
    return shoppinglist_id


@pytest.fixture
def item_id(user_client_with_household, shoppinglist_id_with_item):
    response = user_client_with_household.get(
        f"/api/shoppinglist/{shoppinglist_id_with_item}/items"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "id" in data[0]
    return data[0]["id"]


@pytest.fixture
def recipe_with_items(
    user_client_with_household,
    household_id,
    recipe_name,
    recipe_description,
    recipe_yields,
    recipe_time,
    item_name,
):
    # Create recipe with the item
    recipe_data = {
        "name": recipe_name,
        "description": recipe_description,
        "yields": recipe_yields,
        "time": recipe_time,
        "items": [{"name": item_name, "description": "2 pieces"}],
    }

    response = user_client_with_household.post(
        f"/api/household/{household_id}/recipe", json=recipe_data
    )
    assert response.status_code == 200
    recipe = response.get_json()
    assert "id" in recipe
    return recipe["id"]


@pytest.fixture
def planned_recipe(user_client_with_household, household_id, recipe_with_items):
    """Fixture that creates a meal plan with the test recipe"""
    plan_data = {"recipe_id": recipe_with_items, "cooking_date": FIX_DATETIME}
    response = user_client_with_household.post(
        f"/api/household/{household_id}/planner/recipe", json=plan_data
    )
    assert response.status_code == 200

    # Verify plan was created
    response = user_client_with_household.get(f"/api/household/{household_id}/planner")
    assert response.status_code == 200
    planned_meals = response.get_json()
    assert len(planned_meals) > 0
    assert any(meal["recipe"]["id"] == recipe_with_items for meal in planned_meals)

    return recipe_with_items  # Return recipe_id for convenience

