from marshmallow import fields, Schema, EXCLUDE


class SearchByNameRequest(Schema):
    query = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateItem(Schema):
    class Meta:
        unknown = EXCLUDE
    category = fields.String(
        allow_none=True,
        validate=lambda a: not a or a and not a.isspace()
    )
