from marshmallow import fields, Schema

class CreateUser(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
    username = fields.String(
        required=True,
        validate=lambda a: len(a) > 0,
        load_only=True,
    )
    password = fields.String(
        required=True,
        validate=lambda a: len(a) > 0,
        load_only=True,
    )

class UpdateUser(Schema):
    name = fields.String(
        validate=lambda a: len(a) > 0
    )
    username = fields.String(
        validate=lambda a: len(a) > 0,
        load_only=True,
    )
    password = fields.String(
        validate=lambda a: len(a) > 0,
        load_only=True,
    )