from marshmallow import fields, Schema


class AddStore(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateStore(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())

    # if set this merges the specified store into this store thus combining them to one
    merge_store_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )
