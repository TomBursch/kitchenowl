from marshmallow import EXCLUDE, fields, Schema


class ImportSchema(Schema):
    class Meta:
        unknown = EXCLUDE
        
    class Item(Schema):
        name = fields.String(
            required=True,
            validate=lambda a: a and not a.isspace()
        )
        category = fields.String(
            validate=lambda a: a and not a.isspace()
        )
        icon = fields.String()

    class Recipe(Schema):
        class Meta:
            unknown = EXCLUDE
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
        time = fields.Integer(allow_none=True)
        cook_time = fields.Integer(allow_none=True)
        prep_time = fields.Integer(allow_none=True)
        yields = fields.Integer(allow_none=True)
        source = fields.String(allow_none=True)
        photo = fields.String(allow_none=True)
        items = fields.List(fields.Nested(RecipeItem))
        tags = fields.List(fields.String())

    class Expense(Schema):
        class Meta:
            unknown = EXCLUDE
        class PaidFor(Schema):
            username = fields.String(
                required=True,
                validate=lambda a: a and not a.isspace()
            )
            factor = fields.Integer(
                load_default=1
            )
        class Category(Schema):
            name = fields.String(
                required=True,
                validate=lambda a: a and not a.isspace()
            )
            color = fields.Integer(allow_none=True)

        name = fields.String(
            required=True,
            validate=lambda a: a and not a.isspace()
        )
        amount = fields.Float(required=True)
        date = fields.Integer()
        paid_by = fields.String(
            required=True,
            validate=lambda a: a and not a.isspace()
        )
        paid_for = fields.List(fields.Nested(PaidFor))
        photo = fields.String(allow_none=True)
        category = fields.Nested(Category)

    items = fields.List(fields.Nested(Item))
    recipes = fields.List(fields.Nested(Recipe))
    expenses = fields.List(fields.Nested(Expense))
    member = fields.List(fields.String())
    shoppinglists = fields.List(fields.String())
