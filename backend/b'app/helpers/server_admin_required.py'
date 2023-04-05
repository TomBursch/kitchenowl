from flask import request
from functools import wraps
from flask_jwt_extended import current_user
from app.errors import ForbiddenRequest


def server_admin_required():
    def wrapper(func):
        @wraps(func)
        def decorator(*args, **kwargs):
            if not current_user or not current_user.admin:
                raise ForbiddenRequest(
                    message='Elevated rights required. IP {}'.format(
                        request.remote_addr)
                )
            return func(*args, **kwargs)

        return decorator
    return wrapper
