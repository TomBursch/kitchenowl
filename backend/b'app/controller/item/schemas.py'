from marshmallow import fields, Schema


class SearchByNameRequest(Schema):
    query = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
