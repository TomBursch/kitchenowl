from marshmallow import fields, validates_schema, ValidationError, Schema
from app.models import Item


class AddItemByName(Schema):
    name = fields.String(
        required=True
    )
    description = fields.String()


class AddRecipeItems(Schema):
    class RecipeItem(Schema):
        id = fields.Integer(required=True)
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

    items = fields.List(fields.Nested(RecipeItem))


class CreateList(Schema):
    name = fields.String(
        required=True
    )


class UpdateDescription(Schema):
    description = fields.String(
        required=True
    )

    # def validate_id(self, args):
    #     if not ShoppinglistItem.find_by_ids(args['id'], args['item_id']):
    #         raise ValidationError('Item does not exist')


class RemoveItem(Schema):
    item_id = fields.Integer(
        required=True,
    )

    # def validate_id(self, args):
    #     if not ShoppinglistItem.find_by_id(args['id'], args['item_id']):
    #         raise ValidationError('Item does not exist')
