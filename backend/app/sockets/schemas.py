from marshmallow import Schema, fields


class shoppinglist_item_add(Schema):
    shoppinglist_id = fields.Integer(required=True)
    name = fields.String(
        required=True
    )
    description = fields.String()

class shoppinglist_item_remove(Schema):
    shoppinglist_id = fields.Integer(required=True)
    item_id = fields.Integer(required=True)