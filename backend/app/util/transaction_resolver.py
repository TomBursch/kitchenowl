"""
Transaction Resolver for Shopping List Conflict Resolution.

When clients go offline and queue operations, those operations may conflict
with changes made by other clients while they were disconnected. This module
provides guards for each mutation endpoint that evaluate whether a stale
client operation is still relevant against the current server state.

Core principle: each operation is evaluated individually against the current
server state + timestamps. The backend answers "is this operation still
relevant right now?" — not global event ordering.

When an operation wins (client_timestamp > updated_at), the server sets
updated_at = client_timestamp (not server receive time) so that subsequent
stale operations from other clients are ordered correctly against it.
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import NamedTuple, TYPE_CHECKING

if TYPE_CHECKING:
    from app.models import ShoppinglistItems, History


class Resolution(Enum):
    """Outcome of a conflict resolution check."""

    ACCEPT = "accept"  # Operation should proceed normally
    REJECT = "reject"  # Operation is stale, skip it
    NOOP = "noop"  # Operation has no effect (item already gone, etc.)
    UPDATE_HISTORY = "update_history"  # Update a History record's description


class ResolveResult(NamedTuple):
    """Result of a conflict resolution check."""

    resolution: Resolution
    reason: str


def epoch_ms_to_datetime(epoch_ms: int) -> datetime:
    """Convert epoch milliseconds (as sent by Flutter clients) to UTC datetime."""
    return datetime.fromtimestamp(epoch_ms / 1000, timezone.utc)


def _ensure_aware(dt: datetime) -> datetime:
    """
    Ensure a datetime is timezone-aware (UTC).

    SQLite stores datetimes as naive strings and returns them without tzinfo,
    even when the original value was timezone-aware. PostgreSQL preserves
    timezone info. This helper normalizes both cases to aware-UTC so
    comparisons don't raise TypeError.
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def resolve_remove(
    con: "ShoppinglistItems | None",
    client_timestamp: int | None,
) -> ResolveResult:
    """
    Evaluate whether a remove operation should proceed.

    Resolution table:
      - Item not on list          → NOOP
      - Item on list, no ts       → ACCEPT (backwards compat: no timestamp = always allow)
      - Item on list, ts > updated_at → ACCEPT
      - Item on list, ts <= updated_at → REJECT (item was modified after this remove was queued)

    Args:
        con: The ShoppinglistItems row, or None if item is not on the list.
        client_timestamp: Epoch milliseconds from the client, or None for
            legacy clients that don't send timestamps.

    Returns:
        ResolveResult with the resolution and a human-readable reason.
    """
    if con is None:
        return ResolveResult(Resolution.NOOP, "Item is not on the shopping list")

    # No timestamp provided — backwards compatible, always allow
    if client_timestamp is None:
        return ResolveResult(Resolution.ACCEPT, "No client timestamp (legacy)")

    client_dt = epoch_ms_to_datetime(client_timestamp)

    updated_at = _ensure_aware(con.updated_at)

    if client_dt > updated_at:
        return ResolveResult(
            Resolution.ACCEPT,
            "Client timestamp is newer than last update",
        )
    else:
        return ResolveResult(
            Resolution.REJECT,
            "Item was modified after this remove was queued "
            f"(client_ts={client_dt.isoformat()}, updated_at={updated_at.isoformat()})",
        )


def resolve_update_description(
    con: "ShoppinglistItems | None",
    client_timestamp: int | None,
    most_recent_dropped: "History | None" = None,
) -> ResolveResult:
    """
    Evaluate whether an update-description operation should proceed.

    Resolution table:
      - Item on list, no ts           → ACCEPT (backwards compat)
      - Item on list, ts > updated_at → ACCEPT
      - Item on list, ts <= updated_at → REJECT
      - Item NOT on list, History DROPPED exists with created_at < client_ts
                                       → UPDATE_HISTORY
      - Item NOT on list, no matching History or History created_at >= client_ts
                                       → NOOP

    Args:
        con: The ShoppinglistItems row, or None if item is not on the list.
        client_timestamp: Epoch milliseconds from the client, or None.
        most_recent_dropped: The most recent History record with status=DROPPED
            for this item on this shoppinglist (only needed when con is None).

    Returns:
        ResolveResult with the resolution and a human-readable reason.
    """
    if con is not None:
        # Item is currently on the shopping list
        if client_timestamp is None:
            return ResolveResult(Resolution.ACCEPT, "No client timestamp (legacy)")

        client_dt = epoch_ms_to_datetime(client_timestamp)
        updated_at = _ensure_aware(con.updated_at)

        if client_dt > updated_at:
            return ResolveResult(
                Resolution.ACCEPT,
                "Client timestamp is newer than last update",
            )
        else:
            return ResolveResult(
                Resolution.REJECT,
                "Item was modified after this update was queued "
                f"(client_ts={client_dt.isoformat()}, "
                f"updated_at={updated_at.isoformat()})",
            )
    else:
        # Item is NOT on the shopping list — check if we should update History
        if client_timestamp is None:
            # Backwards compat: no timestamp means this is a legacy client.
            # The PUT endpoint historically acts as an upsert (add item to list
            # if not present), so we ACCEPT to preserve that behavior.
            return ResolveResult(
                Resolution.ACCEPT,
                "No client timestamp (legacy), upsert behavior",
            )

        if most_recent_dropped is None:
            return ResolveResult(
                Resolution.NOOP,
                "Item not on list, no History DROPPED record found",
            )

        client_dt = epoch_ms_to_datetime(client_timestamp)
        history_created_at = _ensure_aware(most_recent_dropped.created_at)

        if history_created_at < client_dt:
            return ResolveResult(
                Resolution.UPDATE_HISTORY,
                "Updating History DROPPED record description "
                f"(history_created_at={history_created_at.isoformat()}, "
                f"client_ts={client_dt.isoformat()})",
            )
        else:
            return ResolveResult(
                Resolution.NOOP,
                "Edit predates the removal "
                f"(history_created_at={history_created_at.isoformat()}, "
                f"client_ts={client_dt.isoformat()})",
            )


def set_updated_at(obj, client_timestamp: int | None) -> None:
    """
    Set updated_at to the client timestamp if provided, bypassing SQLAlchemy's
    onupdate auto-setter.

    This is important for conflict resolution ordering: when an operation wins,
    we record the client's timestamp (not the server receive time) so that
    subsequent stale operations from other clients are correctly compared.

    We use SQLAlchemy's attribute system to set the value, which will be
    persisted on the next flush/commit. The onupdate lambda will be overridden
    because we're explicitly setting the column value.

    Args:
        obj: Any model instance with an updated_at column.
        client_timestamp: Epoch milliseconds, or None to use default behavior.
    """
    if client_timestamp is not None:
        obj.updated_at = epoch_ms_to_datetime(client_timestamp)
