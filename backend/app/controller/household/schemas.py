from marshmallow import fields, Schema, EXCLUDE


class AddHousehold(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    photo = fields.String()
    link = fields.String()
    description = fields.String()
    language = fields.String()
    planner_feature = fields.Boolean()
    expenses_feature = fields.Boolean()
    view_ordering = fields.List(fields.String)
    member = fields.List(fields.Integer)


class UpdateHousehold(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(validate=lambda a: a and not a.isspace())
    photo = fields.String()
    link = fields.String()
    description = fields.String()
    language = fields.String()
    planner_feature = fields.Boolean()
    expenses_feature = fields.Boolean()
    view_ordering = fields.List(fields.String)


class UpdateHouseholdMember(Schema):
    class Meta:
        unknown = EXCLUDE

    admin = fields.Boolean()

class UpdateShoppingListSort(Schema):
    class Meta:
        unknown = EXCLUDE

    sort_type = fields.Integer(required=True, validate=lambda x: 0 <= x <= 3)
    sort_order = fields.Integer(required=True, validate=lambda x: x in [0, 1])


class ReorderShoppingList(Schema):
    class Meta:
        unknown = EXCLUDE

    shoppinglist_id = fields.Integer(required=True)
    new_index = fields.Integer(required=True)
