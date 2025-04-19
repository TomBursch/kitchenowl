from marshmallow import fields, Schema


class CreateUser(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    username = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace() and "@" not in a,
        load_only=True,
    )
    email = fields.String(
        required=False,
        validate=lambda a: a and not a.isspace() and "@" in a,
        load_only=True,
    )
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )


class UpdateUser(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    photo = fields.String()
    username = fields.String(
        validate=lambda a: a and not a.isspace() and "@" not in a,
        load_only=True,
    )
    email = fields.String(
        validate=lambda a: a and not a.isspace() and "@" in a,
        load_only=True,
    )
    password = fields.String(
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    admin = fields.Boolean(
        load_only=True,
    )


class SearchByNameRequest(Schema):
    query = fields.String(required=True, validate=lambda a: a and not a.isspace())


class ConfirmMail(Schema):
    token = fields.String(required=True, validate=lambda a: a and not a.isspace())


class ResetPassword(Schema):
    token = fields.String(required=True, validate=lambda a: a and not a.isspace())
    password = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )


class ForgotPassword(Schema):
    email = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace() and "@" in a,
        load_only=True,
    )
