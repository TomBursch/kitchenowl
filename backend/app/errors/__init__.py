import ipaddress
import os

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
    """Return the forwarded client address only when the direct peer is trusted."""
    remote = request.remote_addr or "untrackable"
    forwarded = request.headers.get("X-Forwarded-For")
    trusted = os.getenv("TRUSTED_PROXIES", "")
    if not forwarded or not trusted or remote == "untrackable":
        return remote
    try:
        peer = ipaddress.ip_address(remote)
        networks = [
            ipaddress.ip_network(value.strip(), strict=False)
            for value in trusted.split(",")
            if value.strip()
        ]
        if not any(peer in network for network in networks):
            return remote
        client = forwarded.split(",", 1)[0].strip()
        return str(ipaddress.ip_address(client))
    except ValueError:
        return remote
