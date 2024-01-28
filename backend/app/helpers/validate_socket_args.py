from marshmallow.exceptions import ValidationError
from app.errors import InvalidUsage
from flask import request
from functools import wraps


def validate_socket_args(schema_cls):
    def validate(func):
        @wraps(func)
        def func_wrapper(*args, **kwargs):
            if not schema_cls:
                raise Exception("Invalid usage. Schema class missing")

            try:
                arguments = schema_cls().load(args[0])
            except ValidationError as exc:
                raise InvalidUsage("{}".format(exc))

            return func(arguments, **kwargs)

        return func_wrapper

    return validate
