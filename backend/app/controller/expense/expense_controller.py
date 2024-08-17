import calendar
from datetime import datetime, timezone, timedelta
from dateutil.relativedelta import relativedelta
from sqlalchemy.sql.expression import desc
from sqlalchemy import or_
from app.errors import NotFoundRequest
from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from sqlalchemy import func
from app import db
from app.helpers import validate_args, authorize_household, RequiredRights
from app.models import Expense, ExpensePaidFor, ExpenseCategory, HouseholdMember
from app.service.recalculate_balances import recalculateBalances
from app.service.file_has_access_or_download import file_has_access_or_download
from .schemas import (
    GetExpenses,
    AddExpense,
    UpdateExpense,
    AddExpenseCategory,
    UpdateExpenseCategory,
    GetExpenseOverview,
)

expense = Blueprint("expense", __name__)
expenseHousehold = Blueprint("expense", __name__)


@expenseHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetExpenses)
def getAllExpenses(args, household_id):
    filter = [Expense.household_id == household_id]
    if "startAfterId" in args:
        filter.append(Expense.id < args["startAfterId"])
    if "startAfterDate" in args:
        filter.append(
            Expense.date
            < datetime.fromtimestamp(args["startAfterDate"] / 1000, timezone.utc)
        )
    if "endBeforeDate" in args:
        filter.append(
            Expense.date
            > datetime.fromtimestamp(args["endBeforeDate"] / 1000, timezone.utc)
        )

    if "view" in args and args["view"] == 1:
        subquery = (
            db.session.query(ExpensePaidFor.expense_id)
            .filter(ExpensePaidFor.user_id == current_user.id)
            .scalar_subquery()
        )
        filter.append(Expense.id.in_(subquery))

    if "filter" in args:
        if None in args["filter"]:
            filter.append(
                or_(
                    Expense.category_id == None, Expense.category_id.in_(args["filter"])
                )
            )
        else:
            filter.append(Expense.category_id.in_(args["filter"]))

    if "search" in args and args["search"]:
        if "*" in args["search"] or "_" in args["search"]:
            query = args["search"].replace("_", "__").replace("*", "%").replace("?", "_")
        else:
            query = "%{0}%".format(args["search"])
        filter.append(Expense.name.ilike(query))

    return jsonify(
        [
            e.obj_to_full_dict()
            for e in Expense.query.order_by(desc(Expense.date))
            .filter(*filter)
            .join(Expense.category, isouter=True)
            .limit(30)
            .all()
        ]
    )


@expense.route("/<int:id>", methods=["GET"])
@jwt_required()
def getExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()
    return jsonify(expense.obj_to_full_dict())


@expenseHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddExpense)
def addExpense(args, household_id):
    member = HouseholdMember.find_by_ids(household_id, args["paid_by"]["id"])
    if not member:
        raise NotFoundRequest()
    expense = Expense()
    expense.name = args["name"]
    expense.amount = args["amount"]
    expense.household_id = household_id
    if "date" in args:
        expense.date = datetime.fromtimestamp(args["date"] / 1000, timezone.utc)
    if "photo" in args and args["photo"] != expense.photo:
        expense.photo = file_has_access_or_download(args["photo"], expense.photo)
    if "category" in args:
        if args["category"] is not None:
            category = ExpenseCategory.find_by_id(args["category"])
            expense.category = category
    if "exclude_from_statistics" in args:
        expense.exclude_from_statistics = args["exclude_from_statistics"]
    expense.paid_by_id = member.user_id
    expense.save()
    member.expense_balance = (member.expense_balance or 0) + expense.amount
    member.save()
    factor_sum = 0
    for user_data in args["paid_for"]:
        if HouseholdMember.find_by_ids(household_id, user_data["id"]):
            factor_sum += user_data["factor"]
    for user_data in args["paid_for"]:
        member_for = HouseholdMember.find_by_ids(household_id, user_data["id"])
        if member_for:
            con = ExpensePaidFor(
                factor=user_data["factor"],
            )
            con.user_id = member_for.user_id
            con.expense = expense
            con.save()
            member_for.expense_balance = (member_for.expense_balance or 0) - (
                con.factor / factor_sum
            ) * expense.amount
            member_for.save()
    return jsonify(expense.obj_to_dict())


@expense.route("/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateExpense)
def updateExpense(args, id):  # noqa: C901
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()

    if "name" in args:
        expense.name = args["name"]
    if "amount" in args:
        expense.amount = args["amount"]
    if "date" in args:
        expense.date = datetime.fromtimestamp(args["date"] / 1000, timezone.utc)
    if "photo" in args and args["photo"] != expense.photo:
        expense.photo = file_has_access_or_download(args["photo"], expense.photo)
    if "category" in args:
        if args["category"] is not None:
            category = ExpenseCategory.find_by_id(args["category"])
            expense.category = category
        else:
            expense.category = None
    if "exclude_from_statistics" in args:
        expense.exclude_from_statistics = args["exclude_from_statistics"]
    if "paid_by" in args:
        member = HouseholdMember.find_by_ids(
            expense.household_id, args["paid_by"]["id"]
        )
        if member:
            expense.paid_by_id = member.user_id
    expense.save()
    if "paid_for" in args:
        for con in expense.paid_for:
            user_ids = [e["id"] for e in args["paid_for"]]
            if con.user.id not in user_ids:
                con.delete()
        for user_data in args["paid_for"]:
            member = HouseholdMember.find_by_ids(expense.household_id, user_data["id"])
            if member:
                con = ExpensePaidFor.find_by_ids(expense.id, member.user_id)
                if con:
                    if "factor" in user_data and user_data["factor"]:
                        con.factor = user_data["factor"]
                else:
                    con = ExpensePaidFor(
                        factor=user_data["factor"],
                    )
                    con.expense = expense
                    con.user_id = member.user_id
                con.save()
    recalculateBalances(expense.household_id)
    return jsonify(expense.obj_to_dict())


@expense.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()

    expense.delete()
    recalculateBalances(expense.household_id)
    return jsonify({"msg": "DONE"})


@expenseHousehold.route("/recalculate-balances")
@jwt_required()
@authorize_household(required=RequiredRights.ADMIN)
def calculateBalances(household_id):
    recalculateBalances(household_id)


@expenseHousehold.route("/categories", methods=["GET"])
@jwt_required()
@authorize_household()
def getExpenseCategories(household_id):
    return jsonify(
        [
            e.obj_to_dict()
            for e in ExpenseCategory.all_from_household_by_name(household_id)
        ]
    )


@expenseHousehold.route("/overview", methods=["GET"])
@jwt_required()
@authorize_household()
@validate_args(GetExpenseOverview)
def getExpenseOverview(args, household_id):
    thisMonthStart = datetime.now(timezone.utc).date().replace(day=1)

    steps = args["steps"] if "steps" in args else 5
    frame = args["frame"] if args["frame"] != None else 2
    page = args["page"] if "page" in args and args["page"] != None else 0

    factor = 1
    by_category_query = (
        Expense.query.filter(
            Expense.household_id == household_id,
            Expense.exclude_from_statistics == False,
        )
        .group_by(Expense.category_id, ExpenseCategory.id)
        .join(Expense.category, isouter=True)
    )

    groupByStr = "YYYY-MM" if "postgresql" in db.engine.name else "%Y-%m" 
    if frame < 3:
        groupByStr += "-DD" if "postgresql" in db.engine.name else "-%d"
    if frame < 1:
        groupByStr += " HH24" if "postgresql" in db.engine.name else" %H"

    by_subframe_query = Expense.query.filter(
        Expense.household_id == household_id,
        Expense.exclude_from_statistics == False,
    ).group_by(
        func.to_char(Expense.date, groupByStr).label("day")
        if "postgresql" in db.engine.name
        else func.strftime(groupByStr, Expense.date)
    )

    if "view" in args and args["view"] == 1:
        filterQuery = (
            db.session.query(ExpensePaidFor.expense_id)
            .filter(ExpensePaidFor.user_id == current_user.id)
            .scalar_subquery()
        )

        s1 = (
            ExpensePaidFor.query.with_entities(
                ExpensePaidFor.expense_id.label("expense_id"),
                func.sum(ExpensePaidFor.factor).label("total"),
            )
            .group_by(ExpensePaidFor.expense_id)
            .subquery()
        )
        s2 = (
            ExpensePaidFor.query.with_entities(
                ExpensePaidFor.expense_id.label("expense_id"),
                (ExpensePaidFor.factor.cast(db.Float) / s1.c.total).label("factor"),
            )
            .filter(ExpensePaidFor.user_id == current_user.id)
            .join(s1, ExpensePaidFor.expense_id == s1.c.expense_id)
            .subquery()
        )

        factor = s2.c.factor

        by_category_query = by_category_query.filter(Expense.id.in_(filterQuery)).join(
            s2
        )
        by_subframe_query = by_subframe_query.filter(Expense.id.in_(filterQuery)).join(
            s2
        )

    def getFilterForStepAgo(stepAgo: int):
        start = None
        end = None
        if frame == 0:  # daily
            start = datetime.now(timezone.utc).date() - timedelta(days=stepAgo)
            end = start + timedelta(hours=24)
        elif frame == 1:  # weekly
            start = datetime.now(timezone.utc).date() - relativedelta(
                days=7, weekday=calendar.MONDAY, weeks=stepAgo
            )
            end = start + timedelta(days=7)
        elif frame == 2:  # monthly
            start = thisMonthStart - relativedelta(months=stepAgo)
            end = start + relativedelta(months=1)
        elif frame == 3:  # yearly
            start = datetime.now(timezone.utc).date().replace(day=1, month=1) - relativedelta(
                years=stepAgo
            )
            end = start + relativedelta(years=1)

        return Expense.date >= start, Expense.date <= end

    def getOverviewForStepAgo(stepAgo: int):
        return {
            "by_category": {
                (e.id or -1): (float(e.balance) or 0)
                for e in by_category_query.with_entities(
                    ExpenseCategory.id.label("id"),
                    func.sum(Expense.amount * factor).label("balance"),
                )
                .filter(*getFilterForStepAgo(stepAgo))
                .all()
            },
            "by_subframe": {
                e.day: (float(e.balance) or 0)
                for e in by_subframe_query.with_entities(
                    func.to_char(Expense.date, groupByStr).label("day")
                    if "postgresql" in db.engine.name
                    else func.strftime(groupByStr, Expense.date).label("day"),
                    func.sum(Expense.amount * factor).label("balance"),
                )
                .filter(*getFilterForStepAgo(stepAgo))
                .all()
            },
        }

    byStep = {
        i: getOverviewForStepAgo(i) for i in range(page * steps, steps + page * steps)
    }

    return jsonify(byStep)


@expenseHousehold.route("/categories", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddExpenseCategory)
def addExpenseCategory(args, household_id):
    category = ExpenseCategory()
    category.name = args["name"]
    category.color = args["color"]
    category.household_id = household_id
    category.save()
    return jsonify(category.obj_to_dict())


@expense.route("/categories/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteExpenseCategoryById(id):
    category = ExpenseCategory.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()
    category.delete()
    return jsonify({"msg": "DONE"})


@expense.route("/categories/<int:id>", methods=["POST"])
@jwt_required()
@validate_args(UpdateExpenseCategory)
def updateExpenseCategory(args, id):
    category = ExpenseCategory.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()

    if "name" in args:
        category.name = args["name"]
    if "color" in args:
        category.color = args["color"]

    category.save()

    if "merge_category_id" in args and args["merge_category_id"] != id:
        mergeCategory = ExpenseCategory.find_by_id(args["merge_category_id"])
        if mergeCategory:
            category.merge(mergeCategory)

    return jsonify(category.obj_to_dict())
