from flask import jsonify, Blueprint
from app.config import (
    BACKEND_VERSION,
    MIN_FRONTEND_VERSION,
    PRIVACY_POLICY_URL,
    TERMS_URL,
    OPEN_REGISTRATION,
    EMAIL_MANDATORY,
)
from app.config import SUPPORTED_LANGUAGES, oidc_clients

health = Blueprint("health", __name__)


@health.route("", methods=["GET"])
def get_health():
    info = {
        "msg": "OK",
        "version": BACKEND_VERSION,
        "min_frontend_version": MIN_FRONTEND_VERSION,
        "oidc_provider": list(oidc_clients.keys()),
    }
    if PRIVACY_POLICY_URL:
        info["privacy_policy"] = PRIVACY_POLICY_URL
    if TERMS_URL:
        info["terms"] = TERMS_URL
    if OPEN_REGISTRATION:
        info["open_registration"] = True
    if EMAIL_MANDATORY:
        info["email_mandatory"] = True
    return jsonify(info)


@health.route("/supported-languages", methods=["GET"])
def getSupportedLanguages():
    return jsonify(SUPPORTED_LANGUAGES)
