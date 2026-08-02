"""Inverse-operation engine for the recipe agent's chat rewind/edit feature.

When the user rewinds the chat to an earlier message (or edits a previous
user message and re-runs the agent), every mutation the agent performed
afterwards must be undone. This module knows, for each mutating tool the
:mod:`app.service.agent_tools` exposes to the agent, how to:

1. **Snapshot** the affected entity right before/after the tool runs so we
   can replay the inverse later. See :func:`capture_before` and
   :func:`build_ops_from_result`.
2. **Detect concurrent modifications** by another user. Each snapshot
   stores the entity's :attr:`updated_at`; on undo we reload the entity
   and refuse to revert anything that has changed in the meantime. The
   user is told which ops were skipped and why.
3. **Apply the inverse** (delete a created entity, restore an updated one
   to its previous field values, re-create a deleted link, ...). See
   :func:`execute_undo_op`.

The agent currently has access to a small allowlist of tools (see
``AGENT_TOOL_ALLOWLIST`` in :mod:`app.service.agent_tools`). The mutating
ones we support here are:

* ``create_recipe`` — reversible by deleting the created recipe.
* ``update_recipe`` — reversible by restoring scalar fields from ``before``.
* ``add_recipe_item`` / ``remove_recipe_item`` — reversible by removing
  / re-adding the link row.
* ``add_recipe_tag`` / ``remove_recipe_tag`` — reversible by removing
  / re-adding the link row.
* ``create_tag`` — intentionally NOT reversed: a tag created mid-chat may
  already be referenced by other recipes the user attached it to manually,
  so deleting it would be destructive.

Read-only tools (``list_*``, ``search_*``, ``get_*``, ``scrape_recipe``,
``web_search_recipes``) do not produce snapshots.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from typing import Any

from app import db
from app.models import (
    AgentMessage,
    AgentMessageRole,
    Item,
    Recipe,
    RecipeItems,
    RecipeTags,
    Tag,
)

_logger = logging.getLogger(__name__)


# Tool reversibility classification. Tools missing from this map are treated
# as read-only and never produce a snapshot.
_REVERSIBLE_TOOLS: set[str] = {
    "create_recipe",
    "update_recipe",
    "add_recipe_item",
    "remove_recipe_item",
    "add_recipe_tag",
    "remove_recipe_tag",
}

_SKIP_TOOLS: set[str] = {
    # Created tags can be reused elsewhere; never auto-delete on undo.
    "create_tag",
}


# Op type constants (mirrored as strings in JSON snapshots).
OP_CREATE = "create"
OP_UPDATE = "update"
OP_DELETE = "delete"


# Conflict reasons surfaced to the UI.
REASON_CONFLICT = "conflict"
REASON_IRREVERSIBLE = "irreversible"
REASON_MISSING = "missing"  # entity was already deleted by someone else
REASON_FAILED = "failed"  # inverse op crashed (logged)


@dataclass
class UndoOp:
    """Single inverse operation captured for a tool message."""

    tool: str
    type: str  # OP_CREATE / OP_UPDATE / OP_DELETE
    entity: str  # short user-facing label, e.g. "recipe", "recipe_item"
    entity_id: int | None
    entity_name: str  # human-readable name, e.g. recipe.name
    before: dict[str, Any] | None
    after: dict[str, Any] | None
    extra: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "tool": self.tool,
            "type": self.type,
            "entity": self.entity,
            "entity_id": self.entity_id,
            "entity_name": self.entity_name,
            "before": self.before,
            "after": self.after,
            "extra": self.extra,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "UndoOp":
        return cls(
            tool=str(data.get("tool", "")),
            type=str(data.get("type", "")),
            entity=str(data.get("entity", "")),
            entity_id=data.get("entity_id"),
            entity_name=str(data.get("entity_name", "")),
            before=data.get("before"),
            after=data.get("after"),
            extra=dict(data.get("extra") or {}),
        )


# ---------------------------------------------------------------- snapshotting


def is_mutating(tool_name: str) -> bool:
    """Return True if ``tool_name`` mutates state and needs snapshotting."""
    return tool_name in _REVERSIBLE_TOOLS or tool_name in _SKIP_TOOLS


def capture_before(tool_name: str, args: dict[str, Any]) -> dict[str, Any] | None:
    """Snapshot the relevant entity *before* the tool mutates it.

    Returns a JSON-serialisable dict the matching :func:`build_ops_from_result`
    call later receives via the ``before`` argument, or ``None`` if no
    pre-state is needed (e.g. for pure ``create`` tools).
    """
    if tool_name == "update_recipe":
        recipe = Recipe.find_by_id(int(args.get("recipe_id", 0)))
        if not recipe:
            return None
        return {"recipe": _recipe_snapshot(recipe)}

    if tool_name == "remove_recipe_item":
        recipe_id = int(args.get("recipe_id", 0))
        item_id = int(args.get("item_id", 0))
        con = RecipeItems.find_by_ids(recipe_id, item_id)
        if not con:
            return None
        recipe = con.recipe
        return {
            "recipe_item": {
                "recipe_id": recipe_id,
                "item_id": item_id,
                "description": con.description or "",
                "optional": bool(con.optional),
                "item_name": con.item.name if con.item else "",
            },
            "recipe_updated_at": _iso(recipe.updated_at) if recipe else None,
            "recipe_name": recipe.name if recipe else "",
        }

    if tool_name == "remove_recipe_tag":
        recipe_id = int(args.get("recipe_id", 0))
        recipe = Recipe.find_by_id(recipe_id)
        if not recipe:
            return None
        tag_id = args.get("tag_id")
        tag_name = str(args.get("name", "")).strip()
        con = None
        if tag_id is not None:
            con = RecipeTags.find_by_ids(recipe.id, int(tag_id))
        elif tag_name:
            tag = Tag.find_by_name(recipe.household_id, tag_name)
            if tag:
                con = RecipeTags.find_by_ids(recipe.id, tag.id)
        if not con:
            return None
        return {
            "recipe_tag": {
                "recipe_id": recipe.id,
                "tag_id": con.tag_id,
                "tag_name": con.tag.name if con.tag else "",
            },
            "recipe_updated_at": _iso(recipe.updated_at),
            "recipe_name": recipe.name,
        }

    return None


def build_ops_from_result(
    tool_name: str,
    args: dict[str, Any],
    result: Any,
    before: dict[str, Any] | None,
) -> list[UndoOp]:
    """Produce the list of :class:`UndoOp` entries for one tool invocation."""
    if tool_name not in _REVERSIBLE_TOOLS:
        return []
    if not isinstance(result, dict):
        return []

    if tool_name == "create_recipe":
        rid = result.get("id")
        if not isinstance(rid, int):
            return []
        return [
            UndoOp(
                tool=tool_name,
                type=OP_CREATE,
                entity="recipe",
                entity_id=rid,
                entity_name=str(result.get("name") or ""),
                before=None,
                after={"recipe": _strip_recipe_dict(result)},
            )
        ]

    if tool_name == "update_recipe":
        if not before or "recipe" not in before:
            return []
        rid = result.get("id")
        return [
            UndoOp(
                tool=tool_name,
                type=OP_UPDATE,
                entity="recipe",
                entity_id=int(rid) if isinstance(rid, int) else None,
                entity_name=str(result.get("name") or ""),
                before=before,
                after={"recipe": _strip_recipe_dict(result)},
            )
        ]

    if tool_name == "add_recipe_item":
        rid = result.get("id")
        if not isinstance(rid, int):
            return []
        item_name = str(args.get("name", "")).strip()
        item = Item.find_by_name(int(result.get("household_id", 0)), item_name)
        if not item:
            return []
        # Avoid emitting an undo op when the link already existed before the
        # tool ran -- in that case there is nothing to delete on rewind.
        # We can detect this by re-checking ``before`` is None and ensuring
        # the link's row was actually created by this call. We approximate
        # by storing the recipe ``updated_at`` as it was returned: the
        # conflict check on undo will catch concurrent changes.
        recipe_updated_at = _iso(result.get("updated_at"))
        return [
            UndoOp(
                tool=tool_name,
                type=OP_CREATE,
                entity="recipe_item",
                entity_id=item.id,
                entity_name=f"{item.name} → {result.get('name') or ''}",
                before=None,
                after={
                    "recipe_id": rid,
                    "item_id": item.id,
                    "recipe_updated_at": recipe_updated_at,
                    "recipe_name": result.get("name") or "",
                    "item_name": item.name,
                },
            )
        ]

    if tool_name == "remove_recipe_item":
        if not before or "recipe_item" not in before:
            return []
        ri = before["recipe_item"]
        return [
            UndoOp(
                tool=tool_name,
                type=OP_DELETE,
                entity="recipe_item",
                entity_id=ri.get("item_id"),
                entity_name=(
                    f"{ri.get('item_name') or ''} → {before.get('recipe_name') or ''}"
                ),
                before=before,
                after=None,
            )
        ]

    if tool_name == "add_recipe_tag":
        rid = result.get("id")
        if not isinstance(rid, int):
            return []
        tag_name = str(args.get("name", "")).strip()
        tag = Tag.find_by_name(int(result.get("household_id", 0)), tag_name)
        if not tag:
            return []
        return [
            UndoOp(
                tool=tool_name,
                type=OP_CREATE,
                entity="recipe_tag",
                entity_id=tag.id,
                entity_name=f"#{tag.name} → {result.get('name') or ''}",
                before=None,
                after={
                    "recipe_id": rid,
                    "tag_id": tag.id,
                    "recipe_updated_at": _iso(result.get("updated_at")),
                    "recipe_name": result.get("name") or "",
                    "tag_name": tag.name,
                },
            )
        ]

    if tool_name == "remove_recipe_tag":
        if not before or "recipe_tag" not in before:
            return []
        rt = before["recipe_tag"]
        return [
            UndoOp(
                tool=tool_name,
                type=OP_DELETE,
                entity="recipe_tag",
                entity_id=rt.get("tag_id"),
                entity_name=(
                    f"#{rt.get('tag_name') or ''} → {before.get('recipe_name') or ''}"
                ),
                before=before,
                after=None,
            )
        ]

    return []


def serialise_ops(ops: list[UndoOp]) -> str | None:
    if not ops:
        return None
    return json.dumps(
        {"ops": [op.to_dict() for op in ops]}, ensure_ascii=False, default=str
    )


def parse_ops(snapshot: str | None) -> list[UndoOp]:
    if not snapshot:
        return []
    try:
        data = json.loads(snapshot)
    except json.JSONDecodeError:
        return []
    raw = data.get("ops") if isinstance(data, dict) else None
    if not isinstance(raw, list):
        return []
    return [UndoOp.from_dict(item) for item in raw if isinstance(item, dict)]


# --------------------------------------------------------------------- preview


@dataclass
class _UndoBatchContext:
    """Per-rewind context shared by preview + execute.

    Captures cross-op knowledge so each individual op can decide whether
    a seemingly conflicting timestamp is actually fine. Two pieces:

    * ``recipes_to_delete``: ids of recipes a ``create_recipe`` op will
      cascade-delete in this batch (when the user did not opt the op
      out). Other ops targeting the same recipe become moot — restoring
      a scalar field on a recipe we are about to delete is pointless,
      and re-adding an item link to a deleted recipe would fail. We
      treat them as silently absorbed by the cascade rather than as
      conflicts.
    * ``known_recipe_timestamps``: set of every ``updated_at`` value the
      agent observed for each recipe across this batch (the after-state
      of every mutating op). When a ``create_recipe`` undo runs and the
      recipe's *current* ``updated_at`` matches any of these, we know
      every change to it came from inside the chat — even if a later
      undo op already shifted the timestamp during this same rewind.
    """

    recipes_to_delete: set[int] = field(default_factory=set)
    known_recipe_timestamps: dict[int, set[str]] = field(default_factory=dict)

    def remember(self, recipe_id: int | None, ts: str | None) -> None:
        if recipe_id is None or not ts:
            return
        self.known_recipe_timestamps.setdefault(int(recipe_id), set()).add(ts)


def _op_recipe_ref(op: UndoOp) -> tuple[int | None, str | None]:
    """Return (recipe_id, recipe_updated_at) the op is associated with.

    Used to merge cross-op knowledge in :class:`_UndoBatchContext`.
    """
    if op.tool == "create_recipe" and op.entity_id is not None:
        ts = ((op.after or {}).get("recipe") or {}).get("updated_at")
        return op.entity_id, ts
    if op.tool == "update_recipe" and op.entity_id is not None:
        after_ts = ((op.after or {}).get("recipe") or {}).get("updated_at")
        before_ts = ((op.before or {}).get("recipe") or {}).get("updated_at")
        return op.entity_id, after_ts or before_ts
    if op.tool == "add_recipe_item" and op.after:
        rid = op.after.get("recipe_id")
        return (int(rid) if isinstance(rid, int) else None), op.after.get(
            "recipe_updated_at"
        )
    if op.tool == "remove_recipe_item" and op.before:
        ri = op.before.get("recipe_item") or {}
        rid = ri.get("recipe_id")
        return (int(rid) if isinstance(rid, int) else None), op.before.get(
            "recipe_updated_at"
        )
    if op.tool == "add_recipe_tag" and op.after:
        rid = op.after.get("recipe_id")
        return (int(rid) if isinstance(rid, int) else None), op.after.get(
            "recipe_updated_at"
        )
    if op.tool == "remove_recipe_tag" and op.before:
        rt = op.before.get("recipe_tag") or {}
        rid = rt.get("recipe_id")
        return (int(rid) if isinstance(rid, int) else None), op.before.get(
            "recipe_updated_at"
        )
    return None, None


def _build_undo_context(
    messages: list[AgentMessage],
    skip_message_ids: set[int] | None = None,
) -> _UndoBatchContext:
    skip = skip_message_ids or set()
    ctx = _UndoBatchContext()
    for msg in messages:
        if msg.role != AgentMessageRole.TOOL:
            continue
        if msg.id in skip:
            continue
        for op in parse_ops(msg.undo_snapshot):
            recipe_id, ts = _op_recipe_ref(op)
            ctx.remember(recipe_id, ts)
            if op.tool == "create_recipe" and op.entity_id is not None:
                ctx.recipes_to_delete.add(int(op.entity_id))
    return ctx


def build_undo_preview(messages: list[AgentMessage]) -> list[dict[str, Any]]:
    """Build the UI-facing preview for rewinding ``messages``.

    Order matches the order the user sees them in chat. Each entry tells
    the UI which message_id the op belongs to (so the user can opt out of
    undoing individual messages), what would happen, and whether a
    conflict / irreversibility blocks the inverse.
    """
    preview: list[dict[str, Any]] = []
    # Build an optimistic context (assume the user does NOT skip anything)
    # so the preview UI can already mark cascade-absorbed ops as reversible
    # rather than scaring the user with a conflict warning that would not
    # actually fire on confirm.
    ctx = _build_undo_context(messages)
    for msg in messages:
        if msg.role != AgentMessageRole.TOOL:
            continue
        tool_name = msg.tool_name or ""
        if tool_name in _SKIP_TOOLS:
            preview.append(
                {
                    "message_id": msg.id,
                    "tool": tool_name,
                    "entity": "tag",
                    "entity_name": "",
                    "reversible": False,
                    "reason": REASON_IRREVERSIBLE,
                }
            )
            continue
        ops = parse_ops(msg.undo_snapshot)
        if not ops:
            continue
        for op in ops:
            absorbed = _absorbed_by_cascade(op, ctx)
            conflict = None if absorbed else _detect_conflict(op, ctx)
            preview.append(
                {
                    "message_id": msg.id,
                    "tool": op.tool,
                    "type": op.type,
                    "entity": op.entity,
                    "entity_id": op.entity_id,
                    "entity_name": op.entity_name,
                    "reversible": conflict is None,
                    "reason": conflict,
                }
            )
    return preview


def execute_undo_for_messages(
    messages: list[AgentMessage], skip_message_ids: set[int]
) -> list[dict[str, Any]]:
    """Apply the inverse of every reversible op in ``messages``.

    Iterates in reverse so newer ops are undone before older ones they may
    depend on (e.g. ``update_recipe`` is reverted before the
    ``create_recipe`` that produced the recipe).

    Returns the list of skipped ops with a reason (``conflict`` /
    ``irreversible`` / ``missing`` / ``failed``) for the UI / response.
    """
    skipped: list[dict[str, Any]] = []
    ctx = _build_undo_context(messages, skip_message_ids)
    for msg in reversed(messages):
        if msg.role != AgentMessageRole.TOOL:
            continue
        if msg.id in skip_message_ids:
            continue
        tool_name = msg.tool_name or ""
        if tool_name in _SKIP_TOOLS:
            skipped.append(
                {
                    "message_id": msg.id,
                    "tool": tool_name,
                    "entity_name": "",
                    "reason": REASON_IRREVERSIBLE,
                }
            )
            continue
        ops = parse_ops(msg.undo_snapshot)
        for op in reversed(ops):
            if _absorbed_by_cascade(op, ctx):
                # Recipe will be deleted by a sibling create_recipe undo;
                # this op becomes a no-op and is intentionally not
                # reported as skipped (no user-facing surprise).
                continue
            conflict = _detect_conflict(op, ctx)
            if conflict is not None:
                skipped.append(
                    {
                        "message_id": msg.id,
                        "tool": op.tool,
                        "entity_name": op.entity_name,
                        "reason": conflict,
                    }
                )
                continue
            try:
                execute_undo_op(op)
            except Exception as exc:  # pragma: no cover - defensive
                _logger.warning(
                    "Failed to undo agent op %s for entity %s: %s",
                    op.tool,
                    op.entity_id,
                    exc,
                )
                db.session.rollback()
                skipped.append(
                    {
                        "message_id": msg.id,
                        "tool": op.tool,
                        "entity_name": op.entity_name,
                        "reason": REASON_FAILED,
                    }
                )
    return skipped


# --------------------------------------------------------------------- inverse


def execute_undo_op(op: UndoOp) -> None:
    """Apply the inverse of a single :class:`UndoOp`.

    Caller must ensure :func:`_detect_conflict` returned ``None`` first.
    """
    if op.tool == "create_recipe":
        recipe = Recipe.find_by_id(op.entity_id) if op.entity_id else None
        if recipe:
            recipe.delete()
        return

    if op.tool == "update_recipe":
        recipe = Recipe.find_by_id(op.entity_id) if op.entity_id else None
        if not recipe or not op.before:
            return
        snapshot = op.before.get("recipe") or {}
        _restore_recipe_scalars(recipe, snapshot)
        recipe.save()
        return

    if op.tool == "add_recipe_item":
        if not op.after:
            return
        con = RecipeItems.find_by_ids(
            int(op.after.get("recipe_id", 0)),
            int(op.after.get("item_id", 0)),
        )
        if con:
            con.delete()
        return

    if op.tool == "remove_recipe_item":
        if not op.before:
            return
        ri = op.before.get("recipe_item") or {}
        recipe = Recipe.find_by_id(int(ri.get("recipe_id", 0)))
        item = Item.find_by_id(int(ri.get("item_id", 0)))
        if not recipe or not item:
            return
        existing = RecipeItems.find_by_ids(recipe.id, item.id)
        if existing:
            return
        con = RecipeItems(
            description=ri.get("description") or "",
            optional=bool(ri.get("optional", False)),
        )
        con.item = item
        con.recipe = recipe
        con.save()
        return

    if op.tool == "add_recipe_tag":
        if not op.after:
            return
        con = RecipeTags.find_by_ids(
            int(op.after.get("recipe_id", 0)),
            int(op.after.get("tag_id", 0)),
        )
        if con:
            con.delete()
        return

    if op.tool == "remove_recipe_tag":
        if not op.before:
            return
        rt = op.before.get("recipe_tag") or {}
        recipe = Recipe.find_by_id(int(rt.get("recipe_id", 0)))
        tag = Tag.find_by_id(int(rt.get("tag_id", 0)))
        if not recipe or not tag:
            return
        existing = RecipeTags.find_by_ids(recipe.id, tag.id)
        if existing:
            return
        con = RecipeTags()
        con.tag = tag
        con.recipe = recipe
        con.save()
        return


# --------------------------------------------------------------- conflict check


def _absorbed_by_cascade(op: UndoOp, ctx: _UndoBatchContext) -> bool:
    """Return True if undoing ``op`` becomes unnecessary because a sibling\n    ``create_recipe`` undo in the same batch is going to cascade-delete\n    the recipe this op targets.\n"""
    if op.tool == "create_recipe":
        return False  # the cascade itself
    recipe_id, _ = _op_recipe_ref(op)
    if recipe_id is None:
        return False
    return int(recipe_id) in ctx.recipes_to_delete


def _detect_conflict(op: UndoOp, ctx: _UndoBatchContext | None = None) -> str | None:
    """Return ``None`` if the op is safely reversible, else a reason code."""
    if op.tool == "create_recipe":
        recipe = Recipe.find_by_id(op.entity_id) if op.entity_id else None
        if not recipe:
            return REASON_MISSING
        if _recipe_unchanged(recipe, op.after):
            return None
        # Relaxation: when every change to this recipe came from inside
        # the current chat (i.e. its current ``updated_at`` matches one
        # of the timestamps the agent itself produced for it), deleting
        # the recipe is still safe — even if a sibling undo op already
        # shifted the timestamp earlier in this batch.
        if ctx is not None and _matches_known_timestamp(recipe, op.entity_id, ctx):
            return None
        return REASON_CONFLICT

    if op.tool == "update_recipe":
        recipe = Recipe.find_by_id(op.entity_id) if op.entity_id else None
        if not recipe:
            return REASON_MISSING
        # The "after" snapshot reflects the state right after the agent's
        # update -- if the recipe's updated_at no longer matches, somebody
        # changed it in the meantime and we must not overwrite their work.
        if not _recipe_unchanged(recipe, op.after):
            return REASON_CONFLICT
        return None

    if op.tool == "add_recipe_item":
        if not op.after:
            return REASON_MISSING
        recipe = Recipe.find_by_id(int(op.after.get("recipe_id", 0)))
        if not recipe:
            return REASON_MISSING
        # The link itself has no exposed updated_at distinct from the
        # recipe's; comparing the recipe's timestamp catches edits to any
        # of its items / tags / scalar fields after the agent's call.
        if _iso(recipe.updated_at) != op.after.get("recipe_updated_at"):
            return REASON_CONFLICT
        return None

    if op.tool == "remove_recipe_item":
        if not op.before:
            return REASON_MISSING
        recipe = Recipe.find_by_id(
            int(op.before.get("recipe_item", {}).get("recipe_id", 0))
        )
        if not recipe:
            return REASON_MISSING
        # If the recipe was edited after the agent removed the item, we
        # don't know whether re-adding the item still matches the user's
        # intent -- play it safe and skip.
        if _iso(recipe.updated_at) != op.before.get("recipe_updated_at"):
            return REASON_CONFLICT
        return None

    if op.tool == "add_recipe_tag":
        if not op.after:
            return REASON_MISSING
        recipe = Recipe.find_by_id(int(op.after.get("recipe_id", 0)))
        if not recipe:
            return REASON_MISSING
        if _iso(recipe.updated_at) != op.after.get("recipe_updated_at"):
            return REASON_CONFLICT
        return None

    if op.tool == "remove_recipe_tag":
        if not op.before:
            return REASON_MISSING
        recipe = Recipe.find_by_id(
            int(op.before.get("recipe_tag", {}).get("recipe_id", 0))
        )
        if not recipe:
            return REASON_MISSING
        if _iso(recipe.updated_at) != op.before.get("recipe_updated_at"):
            return REASON_CONFLICT
        return None

    return REASON_IRREVERSIBLE


# ----------------------------------------------------------------- snapshotting


# Recipe scalar fields that ``update_recipe`` may touch and that we restore
# verbatim on undo. Lists (items / tags) are NOT included: ``update_recipe``
# never modifies them, and the per-item/tag tools have their own undo ops.
_RECIPE_SCALAR_FIELDS: tuple[str, ...] = (
    "name",
    "description",
    "time",
    "cook_time",
    "prep_time",
    "yields",
    "source",
    "visibility",
)


def _recipe_snapshot(recipe: "Recipe") -> dict[str, Any]:
    """Capture the subset of recipe fields we need to restore on undo."""
    snap: dict[str, Any] = {
        "id": recipe.id,
        "updated_at": _iso(recipe.updated_at),
    }
    for name in _RECIPE_SCALAR_FIELDS:
        value = getattr(recipe, name, None)
        if hasattr(value, "value"):
            value = value.value  # SQLAlchemy enums
        snap[name] = value
    return snap


def _strip_recipe_dict(result: dict[str, Any]) -> dict[str, Any]:
    """Trim a tool result down to the fields needed to identify / compare."""
    keep = ("id", "updated_at") + _RECIPE_SCALAR_FIELDS
    out = {k: result.get(k) for k in keep if k in result}
    # Normalise the timestamp so JSON round-trip matches ``_iso(recipe.updated_at)``
    # in :func:`_recipe_unchanged` -- otherwise ``str(datetime)`` and
    # ``datetime.isoformat()`` would diverge and every undo would conflict.
    if "updated_at" in out:
        out["updated_at"] = _iso(out["updated_at"])
    return out


def _restore_recipe_scalars(recipe: "Recipe", snapshot: dict[str, Any]) -> None:
    from app.models.recipe import RecipeVisibility

    for name in _RECIPE_SCALAR_FIELDS:
        if name not in snapshot:
            continue
        value = snapshot[name]
        if name == "visibility" and value is not None:
            try:
                value = RecipeVisibility(int(value))
            except (ValueError, TypeError):
                continue
        setattr(recipe, name, value)


def _recipe_unchanged(recipe: "Recipe", snapshot: dict[str, Any] | None) -> bool:
    if not snapshot:
        return False
    snap = snapshot.get("recipe") if "recipe" in snapshot else snapshot
    if not isinstance(snap, dict):
        return False
    expected = snap.get("updated_at")
    if expected is None:
        return False
    return _iso(recipe.updated_at) == expected


def _matches_known_timestamp(
    recipe: "Recipe", recipe_id: int | None, ctx: _UndoBatchContext
) -> bool:
    """Return True if the recipe's current ``updated_at`` matches any value
    the chat captured for it across this rewind batch (covers timestamps
    set by the original agent calls *and* by sibling undo ops applied
    earlier in the same batch).
    """
    if recipe_id is None:
        return False
    known = ctx.known_recipe_timestamps.get(int(recipe_id))
    if not known:
        return False
    return _iso(recipe.updated_at) in known


def _iso(value: Any) -> str | None:
    """Normalise a datetime / string to a stable ISO-8601 representation."""
    if value is None:
        return None
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)
