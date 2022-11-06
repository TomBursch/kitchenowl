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
