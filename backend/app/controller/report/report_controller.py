from sqlalchemy import desc
from app.helpers import validate_args, server_admin_required
from flask import jsonify, Blueprint
from app.errors import InvalidUsage, NotFoundRequest
from flask_jwt_extended import current_user, jwt_required
from app.models import Report
from .schemas import AddReport

reportBlueprint = Blueprint("report", __name__)


@reportBlueprint.route("", methods=["GET"])
@jwt_required()
@server_admin_required()
def getAllReports():
    return jsonify(
        [e.obj_to_full_dict() for e in Report.query.order_by(desc(Report.id)).all()]
    )


@reportBlueprint.route("/<int:id>", methods=["GET"])
@jwt_required()
@server_admin_required()
def getReport(id):
    report = Report.find_by_id(id)
    if not report:
        raise NotFoundRequest()
    return jsonify(report.obj_to_full_dict())


@reportBlueprint.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteReportById(id):
    report = Report.find_by_id(id)
    if not report:
        raise NotFoundRequest()
    report.delete()
    return jsonify({"msg": "DONE"})


@reportBlueprint.route("", methods=["POST"])
@jwt_required()
@validate_args(AddReport)
def addReport(args: AddReport):
    report = Report(
        created_by_id=current_user.id,
    )
    if args.description is not None:
        report.description = args.description
    if args.user_id is not None:
        report.user_id = args.user_id
    elif args.recipe_id is not None:
        report.recipe_id = args.recipe_id
    else:
        raise InvalidUsage()
    report.save()

    return jsonify(report.obj_to_dict())
