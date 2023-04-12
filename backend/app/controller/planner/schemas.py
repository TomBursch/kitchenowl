from marshmallow import fields, Schema, EXCLUDE
from marshmallow.validate import Range


class AddPlannedRecipe(Schema):
    class Meta:
        unknown = EXCLUDE
    recipe_id = fields.Integer(
        required=True,
    )
    day = fields.Integer(validate=Range(
        min=0, min_inclusive=True, max=6, max_inclusive=True))
    yields = fields.Integer()


class RemovePlannedRecipe(Schema):
    class Meta:
        unknown = EXCLUDE
    day = fields.Integer(validate=Range(
        min=0, min_inclusive=True, max=6, max_inclusive=True))
