"""
Tests for shopping list conflict resolution.

Covers all cases from the resolution table:
  Remove: NOOP (item gone), ACCEPT (legacy), ACCEPT (ts > updated_at), REJECT (ts <= updated_at)
  Update: ACCEPT (legacy), ACCEPT (ts > updated_at), REJECT (ts <= updated_at),
          NOOP (item gone, no history), UPDATE_HISTORY (item gone, history exists)
  Add:    Idempotent (already on list), always succeeds (not on list)
"""

import time
from datetime import datetime, timedelta, timezone

import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _epoch_ms(dt: datetime) -> int:
    """Convert a datetime to epoch milliseconds (what the Flutter client sends)."""
    return int(dt.timestamp() * 1000)


def _now_ms() -> int:
    return _epoch_ms(datetime.now(timezone.utc))


def _add_item_to_list(client, shoppinglist_id, item_name="conflict_item"):
    """Add an item by name and return (item_id, shoppinglist_id)."""
    resp = client.post(
        f"/api/shoppinglist/{shoppinglist_id}/add-item-by-name",
        json={"name": item_name},
    )
    assert resp.status_code == 200
    item_data = resp.get_json()
    return item_data["id"]


def _get_items(client, shoppinglist_id):
    """Get all items on the shopping list."""
    resp = client.get(f"/api/shoppinglist/{shoppinglist_id}/items")
    assert resp.status_code == 200
    return resp.get_json()


# ===========================================================================
# REMOVE conflict resolution
# ===========================================================================


class TestRemoveConflictResolution:
    """Tests for the remove operation conflict resolver."""

    def test_remove_item_not_on_list_is_noop(
        self, user_client_with_household, shoppinglist_id
    ):
        """Removing an item that isn't on the list should succeed (NOOP, no error)."""
        # Add and then remove the item first so we have a valid item_id
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "gone_item"
        )
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id},
        )
        assert resp.status_code == 200

        # Now try to remove it again — should be NOOP, not error
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id},
        )
        assert resp.status_code == 200

    def test_remove_legacy_no_timestamp_always_accepts(
        self, user_client_with_household, shoppinglist_id
    ):
        """Legacy clients (no removed_at) should always be able to remove items."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "legacy_remove"
        )
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id},
        )
        assert resp.status_code == 200

        items = _get_items(user_client_with_household, shoppinglist_id)
        assert not any(i["id"] == item_id for i in items)

    def test_remove_fresh_timestamp_accepts(
        self, user_client_with_household, shoppinglist_id
    ):
        """Remove with a timestamp newer than updated_at should succeed."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "fresh_remove"
        )

        # Use a timestamp well in the future so it's guaranteed > updated_at
        future_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(hours=1))
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id, "removed_at": future_ts},
        )
        assert resp.status_code == 200

        items = _get_items(user_client_with_household, shoppinglist_id)
        assert not any(i["id"] == item_id for i in items)

    def test_remove_stale_timestamp_rejects(
        self, user_client_with_household, shoppinglist_id
    ):
        """Remove with a timestamp older than updated_at should be silently rejected."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "stale_remove"
        )

        # First, update the item's description with a fresh timestamp to bump updated_at
        fresh_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={
                "description": "updated after remove queued",
                "client_timestamp": fresh_ts,
            },
        )
        assert resp.status_code == 200

        # Now try to remove with a stale timestamp (before the update)
        stale_ts = _epoch_ms(datetime.now(timezone.utc) - timedelta(hours=1))
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id, "removed_at": stale_ts},
        )
        assert resp.status_code == 200  # Still returns 200 (no retry)

        # Item should still be on the list
        items = _get_items(user_client_with_household, shoppinglist_id)
        assert any(i["id"] == item_id for i in items)


# ===========================================================================
# UPDATE DESCRIPTION conflict resolution
# ===========================================================================


class TestUpdateDescriptionConflictResolution:
    """Tests for the update-description operation conflict resolver."""

    def test_update_legacy_no_timestamp_accepts(
        self, user_client_with_household, shoppinglist_id
    ):
        """Legacy clients (no client_timestamp) should always be able to update."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "legacy_update"
        )
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "legacy update"},
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("description") == "legacy update"

    def test_update_fresh_timestamp_accepts(
        self, user_client_with_household, shoppinglist_id
    ):
        """Update with timestamp newer than updated_at should succeed."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "fresh_update"
        )
        future_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "fresh update", "client_timestamp": future_ts},
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("description") == "fresh update"

    def test_update_stale_timestamp_rejects(
        self, user_client_with_household, shoppinglist_id
    ):
        """Update with timestamp older than updated_at should be rejected."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "stale_update"
        )

        # First update with a fresh timestamp to bump updated_at
        fresh_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "first update", "client_timestamp": fresh_ts},
        )
        assert resp.status_code == 200

        # Now try to update with a stale timestamp
        stale_ts = _epoch_ms(datetime.now(timezone.utc) - timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "stale update", "client_timestamp": stale_ts},
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("msg") == "CONFLICT_REJECTED"

        # Description should remain the first update
        items = _get_items(user_client_with_household, shoppinglist_id)
        item = next(i for i in items if i["id"] == item_id)
        assert item["description"] == "first update"

    def test_update_item_not_on_list_legacy_upserts(
        self, user_client_with_household, shoppinglist_id
    ):
        """Legacy client updating a non-existent item should upsert (add it)."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "upsert_item"
        )
        # Remove it
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id},
        )
        assert resp.status_code == 200

        # Legacy update (no client_timestamp) should upsert — add item back
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "upserted"},
        )
        assert resp.status_code == 200

        items = _get_items(user_client_with_household, shoppinglist_id)
        assert any(i["id"] == item_id for i in items)

    def test_update_item_not_on_list_with_timestamp_updates_history(
        self, user_client_with_household, shoppinglist_id
    ):
        """
        When item is not on list and a History DROPPED record exists with
        created_at < client_timestamp, should update the History description.
        """
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "history_update_item"
        )

        # Remove the item (creates a History DROPPED record)
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id},
        )
        assert resp.status_code == 200

        # Update with a timestamp in the future (> History DROPPED created_at)
        future_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "updated in history", "client_timestamp": future_ts},
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("msg") == "HISTORY_UPDATED"

        # Item should NOT be back on the list
        items = _get_items(user_client_with_household, shoppinglist_id)
        assert not any(i["id"] == item_id for i in items)

    def test_update_item_not_on_list_stale_timestamp_is_noop(
        self, user_client_with_household, shoppinglist_id
    ):
        """
        When item is not on list, but the edit predates the removal
        (client_timestamp <= History DROPPED created_at), should be NOOP.
        """
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "noop_history_item"
        )

        # Remove the item with a far-future timestamp so History's created_at is in the future
        far_future = _epoch_ms(datetime.now(timezone.utc) + timedelta(days=10))
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id, "removed_at": far_future},
        )
        assert resp.status_code == 200

        # Try to update with a timestamp that's still in the past relative to the removal
        past_ts = _epoch_ms(datetime.now(timezone.utc) - timedelta(hours=1))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "should be ignored", "client_timestamp": past_ts},
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("msg") == "NOOP"


# ===========================================================================
# ADD idempotency
# ===========================================================================


class TestAddIdempotency:
    """Tests that add operations are idempotent."""

    def test_add_item_already_on_list_is_noop(
        self, user_client_with_household, shoppinglist_id
    ):
        """Adding an item that's already on the list should not duplicate it."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "idempotent_add"
        )

        # Add the same item again via PUT (the putItem path)
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": ""},
        )
        assert resp.status_code == 200

        items = _get_items(user_client_with_household, shoppinglist_id)
        matching = [i for i in items if i["id"] == item_id]
        assert len(matching) == 1

    def test_add_item_not_on_list_always_succeeds(
        self, user_client_with_household, shoppinglist_id
    ):
        """Adding an item that's not on the list should always work."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "new_add_item"
        )
        items = _get_items(user_client_with_household, shoppinglist_id)
        assert any(i["id"] == item_id for i in items)


# ===========================================================================
# Backwards compatibility
# ===========================================================================


class TestBackwardsCompatibility:
    """Tests that unknown fields are silently dropped (EXCLUDE behavior)."""

    def test_remove_with_unknown_fields_excluded(
        self, user_client_with_household, shoppinglist_id
    ):
        """RemoveItem schema should silently drop unknown fields."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "exclude_test"
        )
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={
                "item_id": item_id,
                "some_future_field": "should be ignored",
            },
        )
        assert resp.status_code == 200

    def test_update_with_unknown_fields_excluded(
        self, user_client_with_household, shoppinglist_id
    ):
        """UpdateDescription schema should silently drop unknown fields."""
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "exclude_update"
        )
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={
                "description": "test",
                "some_future_field": "should be ignored",
            },
        )
        assert resp.status_code == 200


# ===========================================================================
# Ordering correctness
# ===========================================================================


class TestTimestampOrdering:
    """
    Tests that updated_at is set to client_timestamp (not server receive time)
    so subsequent stale operations are ordered correctly.
    """

    def test_updated_at_set_to_client_timestamp_not_server_time(
        self, user_client_with_household, shoppinglist_id
    ):
        """
        After a successful update with client_timestamp, a slightly-older
        timestamp should be rejected — proving updated_at was set to the
        client's timestamp, not the server's wall clock.
        """
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "ordering_item"
        )

        # Update with a timestamp far in the future
        far_future = _epoch_ms(datetime.now(timezone.utc) + timedelta(days=5))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "future update", "client_timestamp": far_future},
        )
        assert resp.status_code == 200

        # Try to update with a timestamp that's AFTER now but BEFORE far_future
        slightly_less = _epoch_ms(datetime.now(timezone.utc) + timedelta(days=3))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={
                "description": "should be rejected",
                "client_timestamp": slightly_less,
            },
        )
        assert resp.status_code == 200
        data = resp.get_json()
        assert data.get("msg") == "CONFLICT_REJECTED"

        # Confirm original description is preserved
        items = _get_items(user_client_with_household, shoppinglist_id)
        item = next(i for i in items if i["id"] == item_id)
        assert item["description"] == "future update"

    def test_remove_respects_client_timestamp_ordering(
        self, user_client_with_household, shoppinglist_id
    ):
        """
        After an update with a far-future client_timestamp, a remove with
        a timestamp between now and that future should be rejected.
        """
        item_id = _add_item_to_list(
            user_client_with_household, shoppinglist_id, "remove_order_item"
        )

        # Update with far-future timestamp
        far_future = _epoch_ms(datetime.now(timezone.utc) + timedelta(days=5))
        resp = user_client_with_household.put(
            f"/api/shoppinglist/{shoppinglist_id}/item/{item_id}",
            json={"description": "pinned", "client_timestamp": far_future},
        )
        assert resp.status_code == 200

        # Remove with a timestamp between now and far_future
        mid_ts = _epoch_ms(datetime.now(timezone.utc) + timedelta(days=2))
        resp = user_client_with_household.delete(
            f"/api/shoppinglist/{shoppinglist_id}/item",
            json={"item_id": item_id, "removed_at": mid_ts},
        )
        assert resp.status_code == 200

        # Item should still be on the list
        items = _get_items(user_client_with_household, shoppinglist_id)
        assert any(i["id"] == item_id for i in items)
