from marshmallow import fields, Schema


class GetExpenses(Schema):
    view = fields.Integer()
    startAfterId = fields.Integer(
        validate=lambda a: a >= 0
    )


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
    photo = fields.String()
    category = fields.String(
        validate=lambda a: not a or (
            a and not a.isspace()), allow_none=True
    )
    paid_by = fields.Nested(User(), required=True)
    paid_for = fields.List(fields.Nested(
        User()), required=True, validate=lambda a: len(a) > 0)


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
    photo = fields.String()
    category = fields.String(
        validate=lambda a: not a or (
            a and not a.isspace()),
        allow_none=True
    )
    paid_by = fields.Nested(User())
    paid_for = fields.List(fields.Nested(User()))


class AddExpenseCategory(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class UpdateExpenseCategory(Schema):
    name = fields.String(
        validate=lambda a: a and not a.isspace()
    )


class DeleteExpenseCategory(Schema):
    name = fields.String(
        required=True,
        validate=lambda a: a and not a.isspace()
    )


class GetExpenseOverview(Schema):
    view = fields.Integer()
    months = fields.Integer(
        validate=lambda a: a > 0
    )
