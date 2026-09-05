from pydantic import BaseModel, ValidationError
from app.errors import InvalidUsage
from functools import wraps


def validate_socket_args(schema_cls: type[BaseModel]):
    def validate(func):
        @wraps(func)
        def func_wrapper(*args, **kwargs):
            if not schema_cls:
                raise Exception("Invalid usage. Schema class missing")

            try:
                arguments = schema_cls.model_validate_json(args[0])
            except ValidationError as exc:
                raise InvalidUsage("{}".format(exc))

            return func(arguments, **kwargs)

        return func_wrapper

    return validate
