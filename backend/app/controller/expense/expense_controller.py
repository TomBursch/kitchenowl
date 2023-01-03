import calendar
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from sqlalchemy.sql.expression import desc
from app.errors import NotFoundRequest
from flask import jsonify, Blueprint
from flask_jwt_extended import current_user, jwt_required
from sqlalchemy import func
from app import db
from app.helpers import validate_args, admin_required
from app.models import Expense, ExpensePaidFor, User, ExpenseCategory
from .schemas import GetExpenses, AddExpense, UpdateExpense, AddExpenseCategory, UpdateExpenseCategory, GetExpenseOverview

expense = Blueprint('expense', __name__)


@expense.route('', methods=['GET'])
@jwt_required()
@validate_args(GetExpenses)
def getAllExpenses(args):
    filter = []
    if ('startAfterId' in args):
        filter.append(Expense.id < args['startAfterId'])

    if ('view' in args and args['view'] == 1):
        subquery = db.session.query(ExpensePaidFor.expense_id).filter(
            ExpensePaidFor.user_id == current_user.id).scalar_subquery()
        filter.append(Expense.id.in_(subquery))

    return jsonify([e.obj_to_full_dict() for e
                    in Expense.query.order_by(desc(Expense.date)).filter(*filter)
                    .join(Expense.category, isouter=True).limit(30).all()
                    ])


@expense.route('/<id>', methods=['GET'])
@jwt_required()
def getExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    return jsonify(expense.obj_to_full_dict())


@expense.route('', methods=['POST'])
@jwt_required()
@validate_args(AddExpense)
def addExpense(args):
    user = User.find_by_id(args['paid_by']['id'])
    if not user:
        raise NotFoundRequest()
    expense = Expense()
    expense.name = args['name']
    expense.amount = args['amount']
    if 'date' in args:
        expense.date = datetime.fromtimestamp(
            args['date']/1000, timezone.utc)
    if 'photo' in args:
        expense.photo = args['photo']
    if 'category' in args:
        if args['category'] is not None:
            category = ExpenseCategory.find_by_id(args['category'])
            expense.category = category
    expense.paid_by = user
    expense.save()
    user.expense_balance = (user.expense_balance or 0) + expense.amount
    user.save()
    factor_sum = 0
    for user_data in args['paid_for']:
        if User.find_by_id(user_data['id']):
            factor_sum += user_data['factor']
    for user_data in args['paid_for']:
        user_for = User.find_by_id(user_data['id'])
        if user_for:
            con = ExpensePaidFor(
                factor=user_data['factor'],
            )
            con.user = user_for
            con.expense = expense
            con.save()
            user_for.expense_balance = (
                user_for.expense_balance or 0) - (con.factor / factor_sum) * expense.amount
            user_for.save()
    return jsonify(expense.obj_to_dict())


@expense.route('/<id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateExpense)
def updateExpense(args, id):  # noqa: C901
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    if 'name' in args:
        expense.name = args['name']
    if 'amount' in args:
        expense.amount = args['amount']
    if 'date' in args:
        expense.date = datetime.fromtimestamp(
            args['date']/1000, timezone.utc)
    if 'photo' in args:
        expense.photo = args['photo']
    if 'category' in args:
        if args['category'] is not None:
            category = ExpenseCategory.find_by_id(args['category'])
            expense.category = category
        else:
            expense.category = None
    if 'paid_by' in args:
        user = User.find_by_id(args['paid_by']['id'])
        if user:
            expense.paid_by = user
    expense.save()
    if 'paid_for' in args:
        for con in expense.paid_for:
            user_ids = [e['id'] for e in args['paid_for']]
            if con.user.id not in user_ids:
                con.delete()
        for user_data in args['paid_for']:
            user = User.find_by_id(user_data['id'])
            if user:
                con = ExpensePaidFor.find_by_ids(expense.id, user.id)
                if con:
                    if 'factor' in user_data and user_data['factor']:
                        con.factor = user_data['factor']
                else:
                    con = ExpensePaidFor(
                        factor=user_data['factor'],
                    )
                    con.expense = expense
                    con.user = user
                con.save()
    recalculateBalances()
    return jsonify(expense.obj_to_dict())


@expense.route('/<id>', methods=['DELETE'])
@jwt_required()
def deleteExpenseById(id):
    Expense.delete_by_id(id)
    recalculateBalances()
    return jsonify({'msg': 'DONE'})


@expense.route('/recalculate-balances')
@jwt_required()
@admin_required
def calculateBalances():
    recalculateBalances()


def recalculateBalances():
    for user in User.all():
        user.expense_balance = float(Expense.query.with_entities(func.sum(
            Expense.amount).label("balance")).filter(Expense.paid_by == user).first().balance or 0)
        for expense in ExpensePaidFor.query.filter(ExpensePaidFor.user_id == user.id).all():
            factor_sum = Expense.query.with_entities(func.sum(
                ExpensePaidFor.factor).label("factor_sum"))\
                .filter(ExpensePaidFor.expense_id == expense.expense_id).first().factor_sum
            user.expense_balance = user.expense_balance - \
                (expense.factor / factor_sum) * expense.expense.amount
        user.save()


@expense.route('/categories', methods=['GET'])
@jwt_required()
def getExpenseCategories():
    return jsonify([e.obj_to_dict() for e in ExpenseCategory.all_by_name()])


@expense.route('/overview', methods=['GET'])
@jwt_required()
@validate_args(GetExpenseOverview)
def getExpenseOverview(args):
    categories = list(map(lambda x: x.id, ExpenseCategory.all_by_name()))
    categories.append(-1)
    thisMonthStart = datetime.utcnow().date().replace(day=1)

    months = args['months'] if 'months' in args else 5

    factor = 1
    query = Expense.query\
        .group_by(Expense.category_id)\
        .join(Expense.category, isouter=True)

    if ('view' in args and args['view'] == 1):
        filterQuery = db.session.query(ExpensePaidFor.expense_id).filter(
            ExpensePaidFor.user_id == current_user.id).scalar_subquery()

        s1 = ExpensePaidFor.query.with_entities(ExpensePaidFor.expense_id.label("expense_id"), func.sum(
            ExpensePaidFor.factor).label('total')).group_by(ExpensePaidFor.expense_id).subquery()
        s2 = ExpensePaidFor.query.with_entities(ExpensePaidFor.expense_id.label("expense_id"), (ExpensePaidFor.factor.cast(
            db.Float) / s1.c.total).label('factor')).filter(ExpensePaidFor.user_id == current_user.id)\
            .join(s1, ExpensePaidFor.expense_id == s1.c.expense_id).subquery()

        factor = s2.c.factor

        query = query.filter(Expense.id.in_(filterQuery)).join(s2)

    def getOverviewForMonthAgo(monthAgo: int):
        monthStart = thisMonthStart - relativedelta(months=monthAgo)
        monthEnd = monthStart.replace(day=calendar.monthrange(
            monthStart.year, monthStart.month)[1])
        return {
            (e.id or -1): (float(e.balance) or 0) for e in
            query
            .with_entities(ExpenseCategory.id.label("id"), func.sum(Expense.amount * factor).label("balance"))
            .filter(Expense.created_at >= monthStart, Expense.created_at <= monthEnd)
            .all()
        }

    value = [getOverviewForMonthAgo(i) for i in range(0, months)]

    byMonth = {i: {category: (value[i][category] if category in value[i] else 0.0)
                   for category in categories} for i in range(0, months)}

    return jsonify(byMonth)


@expense.route('/categories', methods=['POST'])
@jwt_required()
@validate_args(AddExpenseCategory)
def addExpenseCategory(args):
    category = ExpenseCategory()
    category.name = args['name']
    category.color = args['color']
    category.save()
    return jsonify(category.obj_to_dict())


@expense.route('/categories/<id>', methods=['DELETE'])
@jwt_required()
@admin_required
def deleteExpenseCategoryById(id):
    ExpenseCategory.delete_by_id(id)
    return jsonify({'msg': 'DONE'})


@expense.route('/categories/<id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateExpenseCategory)
def updateExpenseCategory(args, id):
    category = ExpenseCategory.find_by_id(id)

    if not category:
        raise NotFoundRequest()

    if 'name' in args:
        category.name = args['name']
    if 'color' in args:
        category.color = args['color']

    category.save()
    return jsonify(category.obj_to_dict())
