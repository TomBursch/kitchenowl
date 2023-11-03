from marshmallow import fields, Schema, EXCLUDE


class AddHousehold(Schema):
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    photo = fields.String()
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
    language = fields.String()
    planner_feature = fields.Boolean()
    expenses_feature = fields.Boolean()
    view_ordering = fields.List(fields.String)


class UpdateHouseholdMember(Schema):
    class Meta:
        unknown = EXCLUDE

    admin = fields.Boolean()
