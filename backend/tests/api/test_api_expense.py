from datetime import datetime, timezone
from unittest.mock import patch


class _Monday(datetime):
    @classmethod
    def now(cls, tz=None):
        return datetime(2026, 11, 16, 10, tzinfo=timezone.utc)


def test_weekly_overview_on_a_monday(user_client_with_household, household_id):
    user_id = user_client_with_household.get("/api/user").get_json()["id"]
    for amount, day in [
        (10, datetime(2026, 11, 13, 12)),
        (16, datetime(2026, 11, 16, 9)),
    ]:
        response = user_client_with_household.post(
            f"/api/household/{household_id}/expense",
            json={
                "name": "expense",
                "amount": amount,
                "date": int(day.replace(tzinfo=timezone.utc).timestamp() * 1000),
                "paid_by": {"id": user_id},
                "paid_for": [{"id": user_id}],
            },
        )
        assert response.status_code == 200

    with patch("app.controller.expense.expense_controller.datetime", _Monday):
        response = user_client_with_household.get(
            f"/api/household/{household_id}/expense/overview?frame=1&steps=2"
        )
    data = response.get_json()

    assert data["0"]["by_category"] == {"-1": 16.0}
    assert data["1"]["by_category"] == {"-1": 10.0}
