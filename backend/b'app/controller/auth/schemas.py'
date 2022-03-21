from marshmallow import fields, Schema


class Login(Schema):
    username = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
