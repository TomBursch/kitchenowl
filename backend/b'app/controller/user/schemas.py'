from marshmallow import fields, Schema


class CreateUser(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
    username = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )


class UpdateUser(Schema):
    name = fields.String(
        validate=lambda a: a and not a.isspace()
    )
    username = fields.String(
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    password = fields.String(
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    admin = fields.Boolean(
        load_only=True,
    )
