from marshmallow import fields, Schema


class AddTag(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateTag(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())

    # if set this merges the specified tag into this tag thus combining them to one
    merge_tag_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )
