import pytest
from .conftest import FIX_DATETIME


def planned_recipe_day_field_backwards_compatibility(user_client_with_household, household_id, recipe_with_items):
    """Fixture that creates a meal plan with the test recipe"""
    plan_data = {
        'recipe_id': recipe_with_items,
        "day": 0
    }
    response = user_client_with_household.post(
        f'/api/household/{household_id}/planner/recipe',
        json=plan_data
    )
    assert response.status_code == 200
    
    # Verify plan was created
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner'
    )
    assert response.status_code == 200
    planned_meals = response.get_json()
    assert len(planned_meals) > 0
    assert any(meal['recipe']['id'] == recipe_with_items for meal in planned_meals)
    
    return recipe_with_items  # Return recipe_id for convenience


def test_meal_planning_remove(user_client_with_household, household_id, planned_recipe):
    """Test removing meals from plan"""
    # Remove from meal plan
    response = user_client_with_household.delete(
        f'/api/household/{household_id}/planner/recipe/{planned_recipe}',
        json={'day': FIX_DATETIME.weekday()}
    )
    assert response.status_code == 200

    # Verify removal
    response = user_client_with_household.get(
        f'/api/household/{household_id}/planner'
    )
    assert response.status_code == 200
    planned_meals = response.get_json()
    assert not any(meal['recipe']['id'] == planned_recipe for meal in planned_meals)


def test_meal_planning_dayplan_remove_by_day(user_client_with_household, household_id, planned_recipe):
    """Test removing meals from plan"""
    # Remove from meal plan
    response = user_client_with_household.delete(
        f'/api/household/{household_id}/planner/recipe/{planned_recipe}',
        json={'day': FIX_DATETIME.weekday()}
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
        json={'day': FIX_DATETIME.weekday()}
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

