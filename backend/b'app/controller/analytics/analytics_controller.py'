import os
from app.helpers import server_admin_required
from app.models import User, Token, Household
from app.config import UPLOAD_FOLDER
from app import db
from flask import jsonify, Blueprint
from flask_jwt_extended import jwt_required


analytics = Blueprint("analytics", __name__)


@analytics.route("", methods=["GET"])
@jwt_required()
@server_admin_required()
def getBaseAnalytics():
    statvfs = os.statvfs(UPLOAD_FOLDER)
    return jsonify(
        {
            "total_users": User.count(),
            "verified_users": User.query.filter(User.email_verified == True).count(),
            "active_users": db.session.query(Token.user_id)
            .filter(Token.type == "refresh")
            .group_by(Token.user_id)
            .count(),
            "total_households": Household.count(),
            "free_storage": statvfs.f_frsize * statvfs.f_bavail,
            "available_storage": statvfs.f_frsize * statvfs.f_blocks,
            "households": {
                "expense_feature": Household.query.filter(Household.expenses_feature == True).count(),
                "planner_feature": Household.query.filter(Household.planner_feature == True).count(),
            },
        }
    )
