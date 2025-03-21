from marshmallow import fields, Schema, EXCLUDE
from marshmallow.validate import Range


class AddPlannedRecipe(Schema):
    class Meta:
        unknown = EXCLUDE

    recipe_id = fields.Integer(
        required=True,
    )
    cooking_date = fields.Integer()
    yields = fields.Integer()


class RemovePlannedRecipe(Schema):
    class Meta:
        unknown = EXCLUDE

    cooking_date = fields.Integer()

