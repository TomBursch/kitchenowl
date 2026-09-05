from pydantic import BaseModel, ValidationError
from app.errors import InvalidUsage
from flask import request
from functools import wraps


def validate_args(schema_cls: type[BaseModel]):
    def validate(func):
        @wraps(func)
        def func_wrapper(*args, **kwargs):
            try:
                if request.method == "GET":
                    arguments = schema_cls.model_validate(request.args)
                else:
                    arguments = schema_cls.model_validate_json(request.data)
            except ValidationError as exc:
                raise InvalidUsage("{}".format(exc))

            return func(arguments, *args, **kwargs)

        return func_wrapper

    return validate
