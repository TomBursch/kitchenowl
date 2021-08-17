from marshmallow import fields, Schema


class CreateUser(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
    username = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
    password = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
