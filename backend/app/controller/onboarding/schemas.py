from marshmallow import fields, Schema


class OnboardSchema(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    username = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace() and "@" not in a,
    )
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    device = fields.String(
        required=False,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
