from marshmallow import fields, Schema

from app.config import EMAIL_MANDATORY


class Login(Schema):
    username = fields.String(required=True, validate=lambda a: a and not a.isspace())
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


class Signup(Schema):
    username = fields.String(
        required=True, validate=lambda a: a and not a.isspace() and not "@" in a
    )
    email = fields.String(
        required=EMAIL_MANDATORY,
        validate=lambda a: a and not a.isspace() and "@" in a,
        load_only=True,
    )
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
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


class CreateLongLivedToken(Schema):
    device = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )


class GetOIDCLoginUrl(Schema):
    provider = fields.String(
        validate=lambda a: a and not a.isspace(),
        load_only=True,
    )
    kitchenowl_scheme = fields.Boolean(
        required=False,
        default=False,
        load_only=True,
    )


class LoginOIDC(Schema):
    state = fields.String(
        validate=lambda a: a and not a.isspace(),
        required=True,
        load_only=True,
    )
    code = fields.String(
        validate=lambda a: a and not a.isspace(),
        required=True,
        load_only=True,
    )
    device = fields.String(
        validate=lambda a: a and not a.isspace(),
        required=False,
        load_only=True,
    )
