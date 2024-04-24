from datetime import datetime, timezone
import uuid
import gevent

from oic import rndstr
from oic.oic.message import AuthorizationResponse
from oic.oauth2.message import ErrorResponse
from app.helpers import validate_args
from flask import jsonify, Blueprint, request
from flask_jwt_extended import current_user, jwt_required, get_jwt
from app.models import User, Token, OIDCLink, OIDCRequest, ChallengeMailVerify
from app.errors import NotFoundRequest, UnauthorizedRequest, InvalidUsage
from app.service import mail
from .schemas import Login, Signup, CreateLongLivedToken, GetOIDCLoginUrl, LoginOIDC
from app.config import EMAIL_MANDATORY, FRONT_URL, jwt, OPEN_REGISTRATION, oidc_clients

auth = Blueprint("auth", __name__)


# Callback function to check if a JWT exists in the database blocklist
@jwt.token_in_blocklist_loader
def check_if_token_revoked(jwt_header, jwt_payload: dict) -> bool:
    jti = jwt_payload["jti"]
    token = Token.find_by_jti(jti)
    if token is not None:
        token.last_used_at = datetime.now(timezone.utc)
        token.save()

    return token is None


# Register a callback function that takes whatever object is passed in as the
# identity when creating JWTs and converts it to a JSON serializable format.
@jwt.user_identity_loader
def user_identity_lookup(user: User):
    return user.id


# Register a callback function that loads a user from your database whenever
# a protected route is accessed. This should return any python object on a
# successful lookup, or None if the lookup failed for any reason (for example
# if the user has been deleted from the database).
@jwt.user_lookup_loader
def user_lookup_callback(_jwt_header, jwt_data) -> User:
    identity = jwt_data["sub"]
    return User.find_by_id(identity)


@auth.route("", methods=["POST"])
@validate_args(Login)
def login(args):
    username = args["username"].lower().replace(" ", "")
    user = User.find_by_username(username)
    if not user or not user.check_password(args["password"]):
        raise UnauthorizedRequest(
            message="Unauthorized: IP {} login attemp with wrong username or password".format(
                request.remote_addr
            )
        )
    device = "Unkown"
    if "device" in args:
        device = args["device"]

    # Create refresh token
    refreshToken, refreshModel = Token.create_refresh_token(user, device)

    # Create first access token
    accesssToken, _ = Token.create_access_token(user, refreshModel)

    return jsonify(
        {
            "access_token": accesssToken,
            "refresh_token": refreshToken,
            "user": user.obj_to_dict(),
        }
    )


if OPEN_REGISTRATION:

    @auth.route("signup", methods=["POST"])
    @validate_args(Signup)
    def signup(args):
        username = args["username"].lower().replace(" ", "")
        user = User.find_by_username(username)
        if user:
            return "Request invalid: username", 400
        if "email" in args:
            user = User.find_by_email(args["email"])
            if user:
                return "Request invalid: email", 400

        user = User.create(
            username=username,
            name=args["name"],
            password=args["password"],
            email=args["email"] if "email" in args else None,
        )
        if "email" in args and mail.mailConfigured():
            gevent.spawn(
                mail.sendVerificationMail,
                user.id,
                ChallengeMailVerify.create_challenge(user),
            )

        device = "Unkown"
        if "device" in args:
            device = args["device"]

        # Create refresh token
        refreshToken, refreshModel = Token.create_refresh_token(user, device)

        # Create first access token
        accesssToken, _ = Token.create_access_token(user, refreshModel)

        return jsonify(
            {
                "access_token": accesssToken,
                "refresh_token": refreshToken,
                "user": user.obj_to_dict(),
            }
        )


@auth.route("/refresh", methods=["GET"])
@jwt_required(refresh=True)
def refresh():
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message="Unauthorized: IP {} refresh could not get current user".format(
                request.remote_addr
            )
        )

    refreshModel = Token.find_by_jti(get_jwt()["jti"])
    # Refresh token rotation
    refreshToken, refreshModel = Token.create_refresh_token(
        user, oldRefreshToken=refreshModel
    )

    # Create access token
    accesssToken, _ = Token.create_access_token(user, refreshModel)

    return jsonify(
        {
            "access_token": accesssToken,
            "refresh_token": refreshToken,
            "user": user.obj_to_dict(),
        }
    )


@auth.route("", methods=["DELETE"])
@jwt_required()
def logout():
    jwt = get_jwt()
    token = Token.find_by_jti(jwt["jti"])
    if not token:
        raise UnauthorizedRequest(
            message="Unauthorized: IP {}".format(request.remote_addr)
        )

    if token.type == "access":
        token.refresh_token.delete_token_familiy()
    else:
        token.delete()

    return jsonify({"msg": "DONE"})


@auth.route("llt", methods=["POST"])
@jwt_required()
@validate_args(CreateLongLivedToken)
def createLongLivedToken(args):
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message="Unauthorized: IP {}".format(request.remote_addr)
        )

    llToken, _ = Token.create_longlived_token(user, args["device"])

    return jsonify({"longlived_token": llToken})


@auth.route("llt/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteLongLivedToken(id):
    user = current_user
    if not user:
        raise UnauthorizedRequest(
            message="Unauthorized: IP {}".format(request.remote_addr)
        )

    token = Token.find_by_id(id)
    if token.user_id != user.id or token.type != "llt":
        raise UnauthorizedRequest(
            message="Unauthorized: IP {}".format(request.remote_addr)
        )

    token.delete()

    return jsonify({"msg": "DONE"})


if FRONT_URL and len(oidc_clients) > 0:

    @auth.route("oidc", methods=["GET"])
    @jwt_required(optional=True)
    @validate_args(GetOIDCLoginUrl)
    def getOIDCLoginUrl(args):
        provider = args["provider"] if "provider" in args else "custom"
        if not provider in oidc_clients:
            raise NotFoundRequest()
        client = oidc_clients[provider]
        if not client:
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} get login url for unknown OIDC provider".format(
                    request.remote_addr
                )
            )
        state = rndstr()
        nonce = rndstr()
        redirect_uri = (
            "kitchenowl://"
            if "kitchenowl_scheme" in args and args["kitchenowl_scheme"]
            else FRONT_URL
        ) + "/signin/redirect"
        args = {
            "client_id": client.client_id,
            "response_type": "code",
            "scope": ["openid", "profile", "email"],
            "nonce": nonce,
            "state": state,
            "redirect_uri": redirect_uri,
        }

        auth_req = client.construct_AuthorizationRequest(request_args=args)
        login_url = auth_req.request(client.authorization_endpoint)
        OIDCRequest(
            state=state,
            provider=provider,
            nonce=nonce,
            redirect_uri=redirect_uri,
            user_id=current_user.id if current_user else None,
        ).save()
        return jsonify({"login_url": login_url, "state": state, "nonce": nonce})

    @auth.route("callback", methods=["POST"])
    @jwt_required(optional=True)
    @validate_args(LoginOIDC)
    def loginWithOIDC(args):
        # Validate oidc login
        oidc_request = OIDCRequest.find_by_state(args["state"])
        if not oidc_request:
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} login attemp with unknown OIDC state".format(
                    request.remote_addr
                )
            )
        provider = oidc_request.provider
        client = oidc_clients[provider]
        if not client:
            oidc_request.delete()
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} login attemp with unknown OIDC provider".format(
                    request.remote_addr
                )
            )

        if oidc_request.user != current_user:
            if not current_user:
                return "Request invalid: user not signed in for link request", 400
            oidc_request.delete()
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} login attemp for a different account".format(
                    request.remote_addr
                )
            )

        client.parse_response(
            AuthorizationResponse,
            info={"code": args["code"], "state": oidc_request.state},
            sformat="dict",
        )

        tokenResponse = client.do_access_token_request(
            scope=["openid", "profile", "email"],
            state=oidc_request.state,
            request_args={
                "code": args["code"],
                "redirect_uri": oidc_request.redirect_uri,
            },
            authn_method="client_secret_post",
        )
        if isinstance(tokenResponse, ErrorResponse):
            oidc_request.delete()
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} login attemp for OIDC failed".format(
                    request.remote_addr
                )
            )
        userinfo = tokenResponse["id_token"]
        if userinfo["nonce"] != oidc_request.nonce:
            raise UnauthorizedRequest(
                message="Unauthorized: IP {} login attemp for OIDC failed: mismatched nonce".format(
                    request.remote_addr
                )
            )
        oidc_request.delete()

        # find user or create one
        oidcLink = OIDCLink.find_by_ids(userinfo["sub"], provider)
        if current_user:
            if oidcLink and oidcLink.user_id != current_user.id:
                return (
                    "Request invalid: oidc account already linked with other kitchenowl account",
                    400,
                )
            if oidcLink:
                return jsonify({"msg": "DONE"})

            if provider in map(lambda l: l.provider, current_user.oidc_links):
                return "Request invalid: provider already linked with account", 400

            oidcLink = OIDCLink(
                sub=userinfo["sub"], provider=provider, user_id=current_user.id
            ).save()
            oidcLink.user = current_user
        if not oidcLink:
            if "email" in userinfo:
                if User.find_by_email(userinfo["email"].strip()):
                    return "Request invalid: email", 400
            elif EMAIL_MANDATORY:
                return "Request invalid: email", 400

            username = (
                userinfo["preferred_username"].lower().replace(" ", "").replace("@", "")
                if "preferred_username" in userinfo
                else None
            )
            if not username or User.find_by_username(username):
                username = (
                    userinfo["name"].lower().replace(" ", "").replace("@", "")
                    if "name" in userinfo
                    else None
                )
                if not username or User.find_by_username(username):
                    username = userinfo["sub"].lower().replace(" ", "").replace("@", "")
                    if not username or User.find_by_username(username):
                        username = uuid.uuid4().hex
            newUser = User(
                username=username,
                name=(
                    userinfo["name"].strip() if "name" in userinfo else userinfo["sub"]
                ),
                email=userinfo["email"].strip() if "email" in userinfo else None,
                email_verified=(
                    userinfo["email_verified"]
                    if "email_verified" in userinfo
                    else False
                ),
                photo=userinfo["picture"] if "picture" in userinfo else None,
            ).save()
            oidcLink = OIDCLink(
                sub=userinfo["sub"], provider=provider, user_id=newUser.id
            ).save()
            oidcLink.user = newUser

        user: User = oidcLink.user

        # Don't login already logged in user
        if current_user:
            return jsonify({"msg": "DONE"})

        # login user
        device = "Unkown"
        if "device" in args:
            device = args["device"]

        # Create refresh token
        refreshToken, refreshModel = Token.create_refresh_token(user, device)

        # Create first access token
        accesssToken, _ = Token.create_access_token(user, refreshModel)

        return jsonify({"access_token": accesssToken, "refresh_token": refreshToken})
