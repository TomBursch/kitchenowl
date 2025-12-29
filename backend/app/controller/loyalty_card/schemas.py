from marshmallow import fields, Schema


class AddLoyaltyCard(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    barcode_type = fields.String(required=True, validate=lambda a: a and not a.isspace())
    barcode_data = fields.String(required=True, validate=lambda a: a and not a.isspace())
    description = fields.String(allow_none=True)
    color = fields.Integer(validate=lambda i: i >= 0, allow_none=True)
    photo = fields.String(allow_none=True)


class UpdateLoyaltyCard(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    barcode_type = fields.String(validate=lambda a: a and not a.isspace())
    barcode_data = fields.String(validate=lambda a: a and not a.isspace())
    description = fields.String(allow_none=True)
    color = fields.Integer(validate=lambda i: i >= 0, allow_none=True)
    photo = fields.String(allow_none=True)

