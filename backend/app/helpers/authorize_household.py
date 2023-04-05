from functools import wraps
from enum import Enum
from flask_jwt_extended import current_user
from app.errors import UnauthorizedRequest, ForbiddenRequest
from app.models import HouseholdMember


class RequiredRights(Enum):
    MEMBER = 1
    ADMIN = 2
    ADMIN_OR_SELF = 3


def authorize_household(required: RequiredRights = RequiredRights.MEMBER) -> any:
    def wrapper(func):
        @wraps(func)
        def decorator(*args, **kwargs):
            if not 'household_id' in kwargs:
                raise Exception("Wrong usage of authorize_household")
            if required == RequiredRights.ADMIN_OR_SELF and not 'user_id' in kwargs:
                raise Exception("Wrong usage of authorize_household")
            if not current_user:
                raise UnauthorizedRequest()

            if current_user.admin:
                return func(*args, **kwargs)  # case server admin
            if required == RequiredRights.ADMIN_OR_SELF and current_user.id == kwargs['user_id']:
                return func(*args, **kwargs)  # case ressource deals with self

            member = HouseholdMember.find_by_ids(
                kwargs['household_id'], current_user.id)
            if required == RequiredRights.MEMBER and member:
                return func(*args, **kwargs)  # case member

            if (required == RequiredRights.ADMIN or required == RequiredRights.ADMIN_OR_SELF) and member and (member.admin or member.owner):
                return func(*args, **kwargs)  # case admin

            raise ForbiddenRequest()

        return decorator
    return wrapper
