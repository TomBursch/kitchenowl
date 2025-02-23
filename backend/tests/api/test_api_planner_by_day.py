import pytest
from datetime import datetime, timezone

def test_planned_recipe_ad_second_on_another_day_backwards_compatibility(user_client_with_household, household_id, recipe_with_items, planned_recipe):
    """Fixture that creates a meal plan with the test recipe"""
    actual_weekday = pytest.FIX_DATETIME.weekday()
    if actual_weekday == 0:
        new_weekday = 1
    elif actual_weekday == 6:
        new_weekday = 5
    else:
        new_weekday = actual_weekday -1
    plan_data = {
        'recipe_id': recipe_with_items,
        "day": new_weekday
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
    assert len(planned_meals) == 2
    assert sum(meal['recipe']['id'] == recipe_with_items for meal in planned_meals) == 2
    


def test_meal_planning_remove(user_client_with_household, household_id, planned_recipe):
    """Test removing meals from plan"""
    # Remove from meal plan
    response = user_client_with_household.delete(
        f'/api/household/{household_id}/planner/recipe/{planned_recipe}',
        json={'day':pytest.FIX_DATETIME.weekday()}
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
        json={'day': pytest.FIX_DATETIME.weekday()}
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

