from marshmallow import fields, Schema


class AddPlannedRecipe(Schema):
    recipe_id = fields.Integer(
        required=True,
    )
