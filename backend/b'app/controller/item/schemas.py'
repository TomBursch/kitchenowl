from marshmallow import fields, Schema, EXCLUDE


class SearchByNameRequest(Schema):
    query = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateItem(Schema):
    class Meta:
        unknown = EXCLUDE

    class Category(Schema):
        class Meta:
            unknown = EXCLUDE
        id = fields.Integer(
            required=True,
            validate=lambda a: a > 0
        )
        name = fields.String(
            validate=lambda a: not a or a and not a.isspace()
        )

    category = fields.Nested(Category(), allow_none=True)
    icon = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=True,
    )
    name = fields.String(
        validate=lambda a: not a or not a.isspace(),
        allow_none=True,
    )

    # if set this merges the specified item into this item thus combining them to one
    merge_item_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )
