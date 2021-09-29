from marshmallow import fields, Schema


class SetSettingsSchema(Schema):
    planner_feature = fields.List(fields.Boolean())
    expenses_feature = fields.List(fields.Boolean())
