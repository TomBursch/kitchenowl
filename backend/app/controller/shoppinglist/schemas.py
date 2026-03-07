from datetime import datetime, timezone

from marshmallow import fields, Schema, EXCLUDE, ValidationError


def _validate_epoch_ms(value: int) -> None:
    """Reject timestamps that are non-positive or more than 5 minutes in the future."""
    if value <= 0:
        raise ValidationError("Timestamp must be a positive integer.")
    max_ms = int(datetime.now(timezone.utc).timestamp() * 1000) + 300_000  # +5 min
    if value > max_ms:
        raise ValidationError("Timestamp is too far in the future.")


class GetShoppingLists(Schema):
    orderby = fields.Integer()
    recent_limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class AddItemByName(Schema):
    name = fields.String(required=True)
    description = fields.String()


class AddRecipeItems(Schema):
    class RecipeItem(Schema):
        class Meta:
            unknown = EXCLUDE

        id = fields.Integer(required=True)
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        description = fields.String(load_default="")
        optional = fields.Boolean(load_default=True)

    items = fields.List(fields.Nested(RecipeItem))


class CreateList(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateList(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())


class GetItems(Schema):
    orderby = fields.Integer()


class GetRecentItems(Schema):
    # Align deprecated endpoint limit with list endpoint (<=120)
    limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class UpdateDescription(Schema):
    class Meta:
        unknown = EXCLUDE

    description = fields.String(required=True)
    client_timestamp = fields.Integer(validate=_validate_epoch_ms)


class RemoveItem(Schema):
    class Meta:
        unknown = EXCLUDE

    item_id = fields.Integer(
        required=True,
    )
    removed_at = fields.Integer(validate=_validate_epoch_ms)


class RemoveItems(Schema):
    class Meta:
        unknown = EXCLUDE

    class RecipeItem(Schema):
        class Meta:
            unknown = EXCLUDE

        item_id = fields.Integer(
            required=True,
        )
        removed_at = fields.Integer(validate=_validate_epoch_ms)

    items = fields.List(fields.Nested(RecipeItem))
