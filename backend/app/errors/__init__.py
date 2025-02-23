from flask import request


class InvalidUsage(Exception):
    def __init__(self, message="Invalid usage"):
        super(InvalidUsage, self).__init__(message)
        self.message = message


class UnauthorizedRequest(Exception):
    def __init__(self, message=""):
        message = message or "Authorization required. IP {}".format(getClientIp())
        super(UnauthorizedRequest, self).__init__(message)
        self.message = message


class ForbiddenRequest(Exception):
    def __init__(self, message="Request forbidden"):
        super(ForbiddenRequest, self).__init__(message)
        self.message = message


class NotFoundRequest(Exception):
    def __init__(self, message="Requested resource not found"):
        super(NotFoundRequest, self).__init__(message)
        self.message = message


def getClientIp() -> str:
    """
    Get the client IP address from the request headers.
    Potentially unsafe. (We do not have trusted proxies configured).
    """
    if 'X-Forwarded-For' in request.headers:
        return request.headers.getlist("X-Forwarded-For")[0].rpartition(' ')[-1]
    else:
        return request.remote_addr or 'untrackable'