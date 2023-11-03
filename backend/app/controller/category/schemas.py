from marshmallow import fields, Schema, EXCLUDE


class AddCategory(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=lambda a: a and not a.isspace())


class UpdateCategory(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    ordering = fields.Integer(validate=lambda i: i >= 0)

    # if set this merges the specified category into this category thus combining them to one
    merge_category_id = fields.Integer(
        validate=lambda a: a > 0,
        allow_none=True,
    )


class DeleteCategory(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
