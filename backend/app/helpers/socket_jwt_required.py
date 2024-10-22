from functools import wraps
from flask_jwt_extended import verify_jwt_in_request
from flask_socketio import disconnect


def socket_jwt_required(
    optional: bool = False,
    fresh: bool = False,
    refresh: bool = False,
):
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            try:
                verify_jwt_in_request(optional, fresh, refresh)
            except:
                disconnect()
                return
            return fn(*args, **kwargs)

        return decorator

    return wrapper
