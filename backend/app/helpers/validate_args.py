from marshmallow import Schema
from marshmallow.exceptions import ValidationError
from app.errors import InvalidUsage
from flask import request
from functools import wraps


def validate_args(schema_cls: type[Schema]):
    def validate(func):
        @wraps(func)
        def func_wrapper(*args, **kwargs):
            try:
                if request.method == "GET":
                    arguments = schema_cls().load(request.args)
                else:
                    arguments = schema_cls().loads(request.data.decode("utf-8"))
            except ValidationError as exc:
                raise InvalidUsage("{}".format(exc))

            return func(arguments, *args, **kwargs)

        return func_wrapper

    return validate
