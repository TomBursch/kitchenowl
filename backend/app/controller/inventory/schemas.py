from marshmallow import fields, Schema, EXCLUDE


class GetInventories(Schema):
    orderby = fields.Integer()
    recent_limit = fields.Integer(load_default=9, validate=lambda x: x > 0 and x <= 120)


class AddItemByName(Schema):
    name = fields.String(required=True)
    description = fields.String()


class AddShoppinglistItems(Schema):
    class ShoppinglistItem(Schema):
        class Meta:
            unknown = EXCLUDE

        id = fields.Integer(required=True)
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        description = fields.String(load_default="")

    items = fields.List(fields.Nested(ShoppinglistItem))


class CreateList(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateList(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())


class GetItems(Schema):
    orderby = fields.Integer()


class UpdateDescription(Schema):
    description = fields.String(required=True)


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )
    removed_at = fields.Integer()


class RemoveItems(Schema):
    class Item(Schema):
        class Meta:
            unknown = EXCLUDE

        item_id = fields.Integer(
            required=True,
        )
        removed_at = fields.Integer()

    items = fields.List(fields.Nested(Item))
