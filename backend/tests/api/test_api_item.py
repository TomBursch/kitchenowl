from sqlalchemy import event

from app import db
from app.models import Category, Item


def test_get_all_items_loads_categories_without_n_plus_one_queries(
    user_client_with_household, household_id
):
    category = Category.create_by_name(household_id, "Vegetables")
    items = [
        Item(name=f"Catalog item {index}", household_id=household_id, category=category)
        for index in range(10)
    ]
    db.session.add_all(items)
    db.session.commit()

    category_queries = []

    def capture_category_query(
        connection, cursor, statement, parameters, context, executemany
    ):
        normalized = statement.lower()
        if " from category " in normalized or " join category " in normalized:
            category_queries.append(statement)

    event.listen(db.engine, "before_cursor_execute", capture_category_query)
    try:
        response = user_client_with_household.get(f"/api/household/{household_id}/item")
    finally:
        event.remove(db.engine, "before_cursor_execute", capture_category_query)

    assert response.status_code == 200
    response_items = response.get_json()
    assert len(response_items) == len(items)
    response_by_id = {item["id"]: item for item in response_items}
    assert set(response_by_id) == {item.id for item in items}

    response_item = response_by_id[items[0].id]
    assert set(response_item) == set(Item.__table__.columns.keys()) | {"category"}
    assert set(response_item["category"]) == set(Category.__table__.columns.keys())
    assert response_item["category"]["id"] == category.id
    assert response_item["category"]["name"] == category.name
    assert len(category_queries) <= 1
