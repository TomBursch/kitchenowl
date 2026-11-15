from app.models import Category, Household


def test_delete_category_by_name(user_client_with_household, household_id):
    res = user_client_with_household.post(
        f'/api/household/{household_id}/category', json={'name': 'Bakery'}
    )
    assert res.status_code == 200
    category_id = res.get_json()['id']

    res = user_client_with_household.delete(
        f'/api/household/{household_id}/category', json={'name': 'Bakery'}
    )
    assert res.status_code == 200
    assert Category.find_by_id(category_id) is None


def test_delete_category_by_name_not_found(user_client_with_household, household_id):
    res = user_client_with_household.delete(
        f'/api/household/{household_id}/category', json={'name': 'Missing'}
    )
    assert res.status_code == 404


def test_delete_category_by_name_keeps_other_households(
    user_client_with_household, household_id
):
    other = Household(name='Other household').save()
    foreign = Category.create_by_name(other.id, 'Bakery')

    res = user_client_with_household.delete(
        f'/api/household/{household_id}/category', json={'name': 'Bakery'}
    )
    assert res.status_code == 404
    assert Category.find_by_id(foreign.id) is not None
