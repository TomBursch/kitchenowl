from marshmallow import fields, Schema


class AddRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: len(a) > 0
        )
        description = fields.String(
            load_default=''
        )
        optional = fields.Boolean(
            load_default=True
        )

    name = fields.String(
        required=True
    )
    description = fields.String()
    time = fields.Integer()
    items = fields.List(fields.Nested(RecipeItem()))
    tags = fields.List(fields.String())


class UpdateRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: len(a) > 0
        )
        description = fields.String()
        optional = fields.Boolean(load_default=True)

    name = fields.String()
    description = fields.String()
    time = fields.Integer()
    items = fields.List(fields.Nested(RecipeItem()))
    tags = fields.List(fields.String())


class SearchByNameRequest(Schema):
    query = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )


class GetAllFilterRequest(Schema):
    filter = fields.List(fields.String())


class AddItemByName(Schema):
    name = fields.String(
        required=True
    )
    description = fields.String()


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )

class ScrapeRecipe(Schema):
    url = fields.String(
        required=True,
        validate=lambda a: len(a) > 0
    )
