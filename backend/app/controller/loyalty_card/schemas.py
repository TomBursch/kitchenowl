from marshmallow import fields, Schema


class AddLoyaltyCard(Schema):
    name = fields.String(required=True, validate=lambda a: a and not a.isspace())
    barcode_type = fields.String(allow_none=True)
    barcode_data = fields.String(allow_none=True)
    description = fields.String(allow_none=True)
    color = fields.Integer(validate=lambda i: i >= 0, allow_none=True)


class UpdateLoyaltyCard(Schema):
    name = fields.String(validate=lambda a: a and not a.isspace())
    barcode_type = fields.String(allow_none=True)
    barcode_data = fields.String(allow_none=True)
    description = fields.String(allow_none=True)
    color = fields.Integer(validate=lambda i: i >= 0, allow_none=True)


