from marshmallow import fields, Schema


class AddTag(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateTag(Schema):
    name = fields.String(
        validate=lambda a: a and not a.isspace()
    )
