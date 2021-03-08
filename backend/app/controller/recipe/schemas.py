from marshmallow import fields, Schema


class AddRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: len(a) > 0
        )
        description = fields.String(
            default=''
        )
        optional = fields.Boolean(
            default=True
        )

    name = fields.String(
        required=True
    )
    description = fields.String()
    items = fields.List(fields.Nested(RecipeItem()))

class UpdateRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: len(a) > 0
        )
        description = fields.String()
        optional = fields.Boolean(default=True)

    name = fields.String()
    description = fields.String()
    items = fields.List(fields.Nested(RecipeItem()))

class SearchByNameRequest(Schema):
    query = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )


class AddItemByName(Schema):
    name = fields.String(
        required=True
    )
    description = fields.String()


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )
