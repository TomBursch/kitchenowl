from marshmallow import fields, Schema


class CreateUser(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
    username = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
