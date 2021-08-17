from marshmallow import fields, Schema


class Login(Schema):
    username = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
    password = fields.String(
        required=True,
        validate=lambda a: len(a) > 0,
        load_only=True,
    )
