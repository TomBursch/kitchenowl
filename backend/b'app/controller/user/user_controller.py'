import gevent
from app.errors import NotFoundRequest, UnauthorizedRequest
from app.helpers.server_admin_required import server_admin_required
from app.helpers import validate_args
from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from app.models import User, ChallengeMailVerify, ChallengePasswordReset
from app.service import mail
from app.service.file_has_access_or_download import file_has_access_or_download
from .schemas import (
    CreateUser,
    ResetPassword,
    UpdateUser,
    SearchByNameRequest,
    ConfirmMail,
    ForgotPassword,
)


user = Blueprint("user", __name__)


@user.route("/all", methods=["GET"])
@jwt_required()
@server_admin_required()
def getAllUsers():
    return jsonify([e.obj_to_dict(include_email=True) for e in User.query.order_by(User.admin, User.username).all()])


@user.route("", methods=["GET"])
@jwt_required()
def getLoggedInUser():
    return jsonify(current_user.obj_to_full_dict())


@user.route("/<int:id>", methods=["GET"])
@jwt_required()
@server_admin_required()
def getUserById(id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    return jsonify(user.obj_to_dict(include_email=True))


@user.route("", methods=["DELETE"])
@jwt_required()
def deleteUser():
    if not current_user:
        raise UnauthorizedRequest(message="Cannot delete this user")
    current_user.delete()
    return jsonify({"msg": "DONE"})


@user.route("/<int:id>", methods=["DELETE"])
@jwt_required()
@server_admin_required()
def deleteUserById(id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    user.delete()
    return jsonify({"msg": "DONE"})


@user.route("", methods=["POST"])
@jwt_required()
@validate_args(UpdateUser)
def updateUser(args):
    user: User = current_user
    if not user:
        raise NotFoundRequest()
    if "name" in args:
        user.name = args["name"].strip()
    if "password" in args:
        user.set_password(args["password"])
    if "email" in args and args["email"].strip() != user.email:
        if user.find_by_email(args["email"].strip()):
            return "Request invalid: email", 400
        user.email = args["email"].strip()
        user.email_verified = False
        ChallengeMailVerify.delete_by_user(user)
        if mail.mailConfigured():
            gevent.spawn(mail.sendVerificationMail, user.id, ChallengeMailVerify.create_challenge(user))
    if "photo" in args and user.photo != args["photo"]:
        user.photo = file_has_access_or_download(args["photo"], user.photo)
    user.save()
    return jsonify({"msg": "DONE"})


@user.route("/<int:id>", methods=["POST"])
@jwt_required()
@server_admin_required()
@validate_args(UpdateUser)
def updateUserById(args, id):
    user = User.find_by_id(id)
    if not user:
        raise NotFoundRequest()
    if "name" in args:
        user.name = args["name"].strip()
    if "password" in args:
        user.set_password(args["password"])
    if "email" in args and args["email"].strip() != user.email:
        if user.find_by_email(args["email"].strip()):
            return "Request invalid: email", 400
        user.email = args["email"].strip()
        user.email_verified = True
        ChallengeMailVerify.delete_by_user(user)
    if "photo" in args and user.photo != args["photo"]:
        user.photo = file_has_access_or_download(args["photo"], user.photo)
    if "admin" in args:
        user.admin = args["admin"]
    user.save()
    return jsonify({"msg": "DONE"})


@user.route("/new", methods=["POST"])
@jwt_required()
@server_admin_required()
@validate_args(CreateUser)
def createUser(args):
    User.create(
        args["username"].replace(" ", ""),
        args["password"],
        args["name"],
        email=args["email"] if "email" in args else None,
    )
    return jsonify({"msg": "DONE"})


@user.route("/search", methods=["GET"])
@jwt_required()
@validate_args(SearchByNameRequest)
def searchUser(args):
    return jsonify([e.obj_to_dict() for e in User.search_name(args["query"])])


@user.route("/resend-verification-mail", methods=["POST"])
@jwt_required()
def resendVerificationMail():
    user: User = current_user
    if not user:
        raise NotFoundRequest()

    if not mail.mailConfigured():
        raise Exception("Mail service not configured")

    if not user.email_verified:
        mail.sendVerificationMail(user.id, ChallengeMailVerify.create_challenge(user))
    return jsonify({"msg": "DONE"})


@user.route("/confirm-mail", methods=["POST"])
@validate_args(ConfirmMail)
def confirmMail(args):
    challenge = ChallengeMailVerify.find_by_challenge(args["token"])
    if not challenge:
        raise NotFoundRequest()
    user: User = challenge.user
    user.email_verified = True
    user.save()
    ChallengeMailVerify.delete_by_user(user)

    return jsonify({"msg": "DONE"})


@user.route("/reset-password", methods=["POST"])
@validate_args(ResetPassword)
def resetPassword(args):
    challenge = ChallengePasswordReset.find_by_challenge(args["token"])
    if not challenge:
        raise NotFoundRequest()
    user: User = challenge.user
    user.set_password(args["password"])
    user.save()
    ChallengePasswordReset.delete_by_user(user)
    return jsonify({"msg": "DONE"})


@user.route("/forgot-password", methods=["POST"])
@validate_args(ForgotPassword)
def forgotPassword(args):
    if not mail.mailConfigured():
        raise Exception("Mail service not configured")

    user = User.find_by_email(args["email"])
    if not user:
        return jsonify({"msg": "DONE"})

    # if user.email_verified:
    mail.sendPasswordResetMail(user, ChallengePasswordReset.create_challenge(user))
    return jsonify({"msg": "DONE"})
