from marshmallow import fields, Schema, EXCLUDE, validate


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


class ShoppinglistLocation(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(
        load_default=None, allow_none=True, validate=validate.Length(max=128)
    )
    latitude = fields.Float(required=True, validate=validate.Range(min=-90, max=90))
    longitude = fields.Float(required=True, validate=validate.Range(min=-180, max=180))
    radius = fields.Integer(load_default=150, validate=validate.Range(min=50, max=5000))


class CreateList(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    locations = fields.List(fields.Nested(ShoppinglistLocation))


class UpdateList(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    locations = fields.List(fields.Nested(ShoppinglistLocation))


class GetItems(Schema):
    orderby = fields.Integer()


class GetRecentItems(Schema):
    # Align deprecated endpoint limit with list endpoint (<=120)
    limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class UpdateDescription(Schema):
    description = fields.String(required=True)


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )
    removed_at = fields.Integer()


class RemoveItems(Schema):
    class RecipeItem(Schema):
        class Meta:
            unknown = EXCLUDE

        item_id = fields.Integer(
            required=True,
        )
        removed_at = fields.Integer()

    items = fields.List(fields.Nested(RecipeItem))
