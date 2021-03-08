class InvalidUsage(Exception):
    def __init__(self, message):
        super(InvalidUsage, self).__init__(message)
        self.message = message

class UnauthorizedRequest(Exception):
    def __init__(self, message):
        super(UnauthorizedRequest, self).__init__(message)
        self.message = message

class ForbiddenRequest(Exception):
    def __init__(self, message):
        super(ForbiddenRequest, self).__init__(message)
        self.message = message

class NotFoundRequest(Exception):
    def __init__(self, message):
        super(NotFoundRequest, self).__init__(message)
        self.message = message