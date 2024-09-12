from marshmallow import fields, Schema


class AddRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        description = fields.String(load_default="")
        optional = fields.Boolean(load_default=True)

    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    description = fields.String(validate=lambda a: a is not None)
    time = fields.Integer(validate=lambda a: a >= 0)
    cook_time = fields.Integer(validate=lambda a: a >= 0)
    prep_time = fields.Integer(validate=lambda a: a >= 0)
    yields = fields.Integer(validate=lambda a: a >= 0)
    source = fields.String()
    photo = fields.String()
    public = fields.Bool()
    items = fields.List(fields.Nested(RecipeItem()))
    tags = fields.List(fields.String())


class UpdateRecipe(Schema):
    class RecipeItem(Schema):
        name = fields.String(required=True, validate=lambda a: a and not a.isspace())
        description = fields.String()
        optional = fields.Boolean(load_default=True)

    name = fields.String(validate=lambda a: a and not a.isspace())
    description = fields.String(validate=lambda a: a is not None)
    time = fields.Integer(validate=lambda a: a >= 0)
    cook_time = fields.Integer(validate=lambda a: a >= 0)
    prep_time = fields.Integer(validate=lambda a: a >= 0)
    yields = fields.Integer(validate=lambda a: a >= 0)
    source = fields.String()
    photo = fields.String()
    public = fields.Bool()
    items = fields.List(fields.Nested(RecipeItem()))
    tags = fields.List(fields.String())


class SearchByNameRequest(Schema):
    query = fields.String(required=True, validate=lambda a: a and not a.isspace())
    only_ids = fields.Boolean(
        load_default=False,
    )


class GetAllFilterRequest(Schema):
    filter = fields.List(fields.String())


class AddItemByName(Schema):
    name = fields.String(required=True)
    description = fields.String()


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )


class ScrapeRecipe(Schema):
    url = fields.String(required=True, validate=lambda a: a and not a.isspace())
