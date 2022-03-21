from marshmallow import fields, Schema


class AddExpense(Schema):
    class User(Schema):
        id = fields.Integer(
            required=True,
            validate=lambda a: a > 0
        )
        name = fields.String(
            validate=lambda a: a and not a.isspace()
        )
        factor = fields.Integer(
            load_default=1
        )

    name = fields.String(
        required=True
    )
    amount = fields.Float(
        required=True
    )
    paid_by = fields.Nested(User(), required=True)
    paid_for = fields.List(fields.Nested(User()), required=True, validate=lambda a: len(a) > 0)


class UpdateExpense(Schema):
    class User(Schema):
        id = fields.Integer(
            required=True,
            validate=lambda a: a > 0
        )
        name = fields.String(
            validate=lambda a: a and not a.isspace()
        )
        factor = fields.Integer(
            load_default=1
        )

    name = fields.String()
    amount = fields.Float()
    paid_by = fields.Nested(User())
    paid_for = fields.List(fields.Nested(User()))
