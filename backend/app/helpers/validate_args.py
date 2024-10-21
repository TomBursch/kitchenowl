from marshmallow import Schema
from marshmallow.exceptions import ValidationError
from app.errors import InvalidUsage
from flask import request
from functools import wraps


def validate_args(schema_cls: type[Schema]):
    def validate(func):
        @wraps(func)
        def func_wrapper(*args, **kwargs):
            if not schema_cls:
                raise Exception("Invalid usage. Schema class missing")

            if request.method == "GET":
                request_data = request.args
                load_fn = schema_cls().load
            else:
                request_data = request.data.decode("utf-8")
                load_fn = schema_cls().loads

            try:
                arguments = load_fn(request_data)
            except ValidationError as exc:
                raise InvalidUsage("{}".format(exc))

            return func(arguments, *args, **kwargs)

        return func_wrapper

    return validate
