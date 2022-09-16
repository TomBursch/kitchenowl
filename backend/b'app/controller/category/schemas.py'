from marshmallow import fields, Schema


class AddCategory(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateCategory(Schema):
    name = fields.String(
        validate=lambda a: a and not a.isspace()
    )


class DeleteCategory(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )
