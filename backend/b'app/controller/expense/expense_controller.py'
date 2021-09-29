from app.errors import NotFoundRequest
from flask import jsonify
from flask_jwt_extended import jwt_required
from app import app
from sqlalchemy import func
from app.helpers import validate_args, admin_required
from app.models import Expense, ExpensePaidFor, User
from .schemas import AddExpense, UpdateExpense


@app.route('/expense', methods=['GET'])
@jwt_required()
def getAllExpenses():
    return jsonify([e.obj_to_full_dict() for e in Expense.all()])


@app.route('/expense/<id>', methods=['GET'])
@jwt_required()
def getExpenseById(id):
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    return jsonify(expense.obj_to_full_dict())


@app.route('/expense', methods=['POST'])
@jwt_required()
@validate_args(AddExpense)
def addExpense(args):
    user = User.find_by_id(args['paid_by']['id'])
    if not user:
        raise NotFoundRequest()
    expense = Expense()
    expense.name = args['name']
    expense.amount = args['amount']
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


@app.route('/expense/<id>', methods=['POST'])
@jwt_required()
@validate_args(UpdateExpense)
def updateExpense(args, id):  # noqa: C901
    expense = Expense.find_by_id(id)
    if not expense:
        raise NotFoundRequest()
    if 'name' in args and args['name']:
        expense.name = args['name']
    if 'amount' in args and args['amount']:
        expense.amount = args['amount']
    if 'paid_by' in args and args['paid_by']:
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
            user = User.find_by_name(user_data['id'])
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
    calculateBalances()
    return jsonify(expense.obj_to_dict())


@app.route('/expense/<id>', methods=['DELETE'])
@jwt_required()
def deleteExpenseById(id):
    Expense.delete_by_id(id)
    calculateBalances()
    return jsonify({'msg': 'DONE'})


@app.route('/expense/recalculate-balances')
@jwt_required()
@admin_required
def calculateBalances():
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
