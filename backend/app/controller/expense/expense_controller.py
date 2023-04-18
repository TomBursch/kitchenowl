import calendar
from datetime import datetime, timezone
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
from .schemas import GetExpenses, AddExpense, UpdateExpense, AddExpenseCategory, UpdateExpenseCategory, GetExpenseOverview

expense = Blueprint('expense', __name__)
expenseHousehold = Blueprint('expense', __name__)


@expenseHousehold.route('', methods=['GET'])
@jwt_required()
@authorize_household()
@validate_args(GetExpenses)
def getAllExpenses(args, household_id):
    filter = [Expense.household_id == household_id]
    if 'startAfterId' in args:
        filter.append(Expense.id < args['startAfterId'])

    if 'view' in args and args['view'] == 1:
        subquery = db.session.query(ExpensePaidFor.expense_id).filter(
            ExpensePaidFor.user_id == current_user.id).scalar_subquery()
        filter.append(Expense.id.in_(subquery))

    if 'filter' in args:
        if None in args['filter']:
            filter.append(or_(Expense.category_id == None,
                          Expense.category_id.in_(args['filter'])))
        else:
            filter.append(Expense.category_id.in_(args['filter']))

    return jsonify([e.obj_to_full_dict() for e
                    in Expense.query.order_by(desc(Expense.date)).filter(*filter)
                    .join(Expense.category, isouter=True).limit(30).all()
                    ])


@expense.route('/<int:id>', methods=['GET'])
@jwt_required()
def getExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()
    return jsonify(expense.obj_to_full_dict())


@expenseHousehold.route('', methods=['POST'])
@jwt_required()
@authorize_household()
@validate_args(AddExpense)
def addExpense(args, household_id):
    member = HouseholdMember.find_by_ids(household_id, args['paid_by']['id'])
    if not member:
        raise NotFoundRequest()
    expense = Expense()
    expense.name = args['name']
    expense.amount = args['amount']
    expense.household_id = household_id
    if 'date' in args:
        expense.date = datetime.fromtimestamp(
            args['date']/1000, timezone.utc)
    if 'photo' in args:
        expense.photo = args['photo']
    if 'category' in args:
        if args['category'] is not None:
            category = ExpenseCategory.find_by_id(args['category'])
            expense.category = category
    expense.paid_by_id = member.user_id
    expense.save()
    member.expense_balance = (member.expense_balance or 0) + expense.amount
    member.save()
    factor_sum = 0
    for user_data in args['paid_for']:
        if HouseholdMember.find_by_ids(household_id, user_data['id']):
            factor_sum += user_data['factor']
    for user_data in args['paid_for']:
        member_for = HouseholdMember.find_by_ids(household_id, user_data['id'])
        if member_for:
            con = ExpensePaidFor(
                factor=user_data['factor'],
            )
            con.user_id = member_for.user_id
            con.expense = expense
            con.save()
            member_for.expense_balance = (
                member_for.expense_balance or 0) - (con.factor / factor_sum) * expense.amount
            member_for.save()
    return jsonify(expense.obj_to_dict())


@expense.route('/<int:id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateExpense)
def updateExpense(args, id):  # noqa: C901
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()

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
        member = HouseholdMember.find_by_ids(
            expense.household_id, args['paid_by']['id'])
        if member:
            expense.paid_by_id = member.user_id
    expense.save()
    if 'paid_for' in args:
        for con in expense.paid_for:
            user_ids = [e['id'] for e in args['paid_for']]
            if con.user.id not in user_ids:
                con.delete()
        for user_data in args['paid_for']:
            member = HouseholdMember.find_by_ids(
                expense.household_id, user_data['id'])
            if member:
                con = ExpensePaidFor.find_by_ids(expense.id, member.user_id)
                if con:
                    if 'factor' in user_data and user_data['factor']:
                        con.factor = user_data['factor']
                else:
                    con = ExpensePaidFor(
                        factor=user_data['factor'],
                    )
                    con.expense = expense
                    con.user_id = member.user_id
                con.save()
    recalculateBalances(expense.household_id)
    return jsonify(expense.obj_to_dict())


@expense.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deleteExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    expense.checkAuthorized()

    expense.delete()
    recalculateBalances(expense.household_id)
    return jsonify({'msg': 'DONE'})


@expenseHousehold.route('/recalculate-balances')
@jwt_required()
@authorize_household(required=RequiredRights.ADMIN)
def calculateBalances(household_id):
    recalculateBalances(household_id)


def recalculateBalances(household_id):
    for member in HouseholdMember.find_by_household(household_id):
        member.expense_balance = float(Expense.query.with_entities(func.sum(
            Expense.amount).label("balance")).filter(Expense.paid_by_id == member.user_id, Expense.household_id == household_id).first().balance or 0)
        for paid_for in ExpensePaidFor.query.filter(ExpensePaidFor.user_id == member.user_id, ExpensePaidFor.expense_id.in_(db.session.query(Expense.id).filter(
                Expense.household_id == household_id).scalar_subquery())).all():
            factor_sum = Expense.query.with_entities(func.sum(
                ExpensePaidFor.factor).label("factor_sum"))\
                .filter(ExpensePaidFor.expense_id == paid_for.expense_id).first().factor_sum
            member.expense_balance = member.expense_balance - \
                (paid_for.factor / factor_sum) * paid_for.expense.amount
        member.save()


@expenseHousehold.route('/categories', methods=['GET'])
@jwt_required()
@authorize_household()
def getExpenseCategories(household_id):
    return jsonify([e.obj_to_dict() for e in ExpenseCategory.all_from_household_by_name(household_id)])


@expenseHousehold.route('/overview', methods=['GET'])
@jwt_required()
@authorize_household()
@validate_args(GetExpenseOverview)
def getExpenseOverview(args, household_id):
    categories = list(
        map(lambda x: x.id, ExpenseCategory.all_from_household_by_name(household_id)))
    categories.append(-1)
    thisMonthStart = datetime.utcnow().date().replace(day=1)

    months = args['months'] if 'months' in args else 5

    factor = 1
    query = Expense.query\
        .filter(Expense.household_id == household_id)\
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
            .filter(Expense.date >= monthStart, Expense.date <= monthEnd)
            .all()
        }

    value = [getOverviewForMonthAgo(i) for i in range(0, months)]

    byMonth = {i: {category: (value[i][category] if category in value[i] else 0.0)
                   for category in categories} for i in range(0, months)}

    return jsonify(byMonth)


@expenseHousehold.route('/categories', methods=['POST'])
@jwt_required()
@authorize_household()
@validate_args(AddExpenseCategory)
def addExpenseCategory(args, household_id):
    category = ExpenseCategory()
    category.name = args['name']
    category.color = args['color']
    category.household_id = household_id
    category.save()
    return jsonify(category.obj_to_dict())


@expense.route('/categories/<int:id>', methods=['DELETE'])
@jwt_required()
def deleteExpenseCategoryById(id):
    category = ExpenseCategory.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()
    category.delete()
    return jsonify({'msg': 'DONE'})


@expense.route('/categories/<int:id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateExpenseCategory)
def updateExpenseCategory(args, id):
    category = ExpenseCategory.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()

    if 'name' in args:
        category.name = args['name']
    if 'color' in args:
        category.color = args['color']

    category.save()
    return jsonify(category.obj_to_dict())
