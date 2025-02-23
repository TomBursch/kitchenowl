from datetime import datetime, timezone
import pytest

def test_meal_planning_basic(user_client_with_household, household_id, planned_recipe):
    """Test basic meal planning operations"""
    # Get planned meals and verify the recipe is there
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner'
    )
    assert response.status_code == 200
    planned_meals = response.get_json()
    print(f"planned meals: {planned_meals}")

    assert len(planned_meals) == 1
    assert any(meal['recipe']['id'] == planned_recipe for meal in planned_meals)


def test_meal_planning_cooking_date_field(user_client_with_household, household_id, planned_recipe):
    """Test basic meal planning operations"""
    # Get planned meals and verify the recipe is there
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner'
    )
    assert response.status_code == 200
    planned_meals = response.get_json()
    actual = datetime.fromtimestamp(planned_meals[0]["cooking_date"]/1000, timezone.utc).replace(tzinfo=None)
    expected = pytest.FIX_DATETIME
    assert actual == expected


def test_meal_planning_remove_by_datetime(user_client_with_household, household_id, planned_recipe):
    """Test removing meals from plan"""
    # Remove from meal plan
    response = user_client_with_household.delete(
        f'/api/household/{household_id}/planner/recipe/{planned_recipe}',
        json={'cooking_date': pytest.FIX_DATETIME.isoformat()}
    )
    assert response.status_code == 200

    # Verify removal
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner'
    )
    assert response.status_code == 200
    planned_meals = response.get_json()
    assert not any(meal['recipe']['id'] == planned_recipe for meal in planned_meals)


def test_recent_planned_recipes(user_client_with_household, household_id, planned_recipe):
    """Test getting recently planned recipes"""
    # First remove the recipe from the plan
    response = user_client_with_household.delete(
        f'/api/household/{household_id}/planner/recipe/{planned_recipe}',
        json={'cooking_date': pytest.FIX_DATETIME.isoformat()}
    )
    assert response.status_code == 200

    # Now get recent recipes - should include our recently dropped recipe
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner/recent-recipes'
    )
    assert response.status_code == 200
    recent_recipes = response.get_json()
    assert len(recent_recipes) > 0
    assert any(recipe['id'] == planned_recipe for recipe in recent_recipes)


def test_suggested_recipes(user_client_with_household, household_id, recipe_with_items):
    """Test recipe suggestions functionality"""
    # Get suggested recipes
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner/suggested-recipes'
    )
    assert response.status_code == 200
    suggested_recipes = response.get_json()
    assert isinstance(suggested_recipes, list)  # Should return a list, even if empty

    # Refresh suggestions
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner/refresh-suggested-recipes'
    )
    assert response.status_code == 200
    refreshed_suggestions = response.get_json()
    assert isinstance(refreshed_suggestions, list)
