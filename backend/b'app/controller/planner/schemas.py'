from marshmallow import fields, Schema
from marshmallow.validate import Range


class AddPlannedRecipe(Schema):
    recipe_id = fields.Integer(
        required=True,
    )
    day = fields.Integer(validate=Range(
        min=0, min_inclusive=True, max=6, max_inclusive=True))


class RemovePlannedRecipe(Schema):
    day = fields.Integer(validate=Range(
        min=0, min_inclusive=True, max=6, max_inclusive=True))
