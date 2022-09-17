from marshmallow import fields, Schema, EXCLUDE


class AddCategory(Schema):
    class Meta:
        unknown = EXCLUDE
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateCategory(Schema):
    name = fields.String(
        validate=lambda a: a and not a.isspace()
    )
    ordering = fields.Integer(
        validate=lambda i: i >= 0
    )


class DeleteCategory(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
