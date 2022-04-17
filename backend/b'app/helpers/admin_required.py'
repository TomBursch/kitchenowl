from app.models import User
from functools import wraps
from flask_jwt_extended import get_jwt_identity
from app.errors import UnauthorizedRequest


def admin_required(func):
    @wraps(func)
    def func_wrapper(*args, **kwargs):
        user = User.find_by_username(get_jwt_identity())
        if not user or not (user.owner or user.admin):
            raise UnauthorizedRequest(
                message='Elevated rights required'
            )
        return func(*args, **kwargs)

    return func_wrapper


def owner_required(func):
    @wraps(func)
    def func_wrapper(*args, **kwargs):
        user = User.find_by_username(get_jwt_identity())
        if not user or not user.owner:
            raise UnauthorizedRequest(
                message='Elevated rights required'
            )
        return func(*args, **kwargs)

    return func_wrapper
