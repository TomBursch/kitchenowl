from app.models import Category, Household


def test_update_item_sets_and_removes_category_and_icon(
    user_client_with_household, household_id, item_id
):
    category = user_client_with_household.post(
        f'/api/household/{household_id}/category', json={'name': 'Vegetables'}
    ).get_json()

    res = user_client_with_household.post(
        f'/api/item/{item_id}',
        json={'icon': 'mushroom', 'category': {'id': category['id'], 'name': 'Vegetables'}},
    )
    assert res.status_code == 200
    assert res.get_json()['icon'] == 'mushroom'
    assert res.get_json()['category_id'] == category['id']

    res = user_client_with_household.post(
        f'/api/item/{item_id}', json={'icon': None, 'category': None}
    )
    assert res.status_code == 200
    assert res.get_json()['icon'] is None
    assert res.get_json()['category_id'] is None


def test_update_item_rejects_category_of_other_household(
    user_client_with_household, item_id
):
    other = Household(name='Other household').save()
    foreign = Category.create_by_name(other.id, 'Foreign')

    res = user_client_with_household.post(
        f'/api/item/{item_id}', json={'category': {'id': foreign.id}}
    )
    assert res.status_code == 400


def test_update_item_keeps_name_used_by_other_item(
    user_client_with_household, shoppinglist_id, item_id, item_name
):
    user_client_with_household.post(
        f'/api/shoppinglist/{shoppinglist_id}/add-item-by-name', json={'name': 'Bread'}
    )

    res = user_client_with_household.post(f'/api/item/{item_id}', json={'name': 'Bread'})
    assert res.status_code == 200
    assert res.get_json()['name'] == item_name
