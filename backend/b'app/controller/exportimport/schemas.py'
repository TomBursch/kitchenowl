from marshmallow import fields, Schema


class ImportSchema(Schema):
    class Item(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: a and not a.isspace()
        )

    class Recipe(Schema):
        class RecipeItem(Schema):
            name = fields.String(
                required=True,
                validate=lambda a: a and not a.isspace()
            )
            optional = fields.Boolean(
                load_default=False
            )
            description = fields.String(
                load_default=''
            )

        name = fields.String(
            required=True,
            validate=lambda a: a and not a.isspace()
        )
        description = fields.String(
            load_default=''
        )
        items = fields.List(fields.Nested(RecipeItem))

    items = fields.List(fields.Nested(Item))
    recipes = fields.List(fields.Nested(Recipe))
