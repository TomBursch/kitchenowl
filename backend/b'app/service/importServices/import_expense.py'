
from datetime import datetime, timezone
from flask_jwt_extended import current_user
from app.models import Household, Expense, ExpensePaidFor, File, ExpenseCategory


def importExpense(household: Household, args: dict):
    expense = Expense()
    expense.household = household
    expense.name = args['name']
    expense.date = datetime.fromtimestamp(
        args['date']/1000, timezone.utc)
    expense.amount = args['amount']
    if 'photo' in args:
        f = File.find(args['photo'])
        if f and f.created_by == current_user.id:
            expense.photo = f.filename
    if 'category' in args:
        category = ExpenseCategory.find_by_name(
            household.id, args['category']['name'])
        if not category:
            category = ExpenseCategory()
            category.name = args['category']['name']
            category.color = args['category']['color']
            category.household_id = household.id
            category = category.save()
        expense.category = category

    paid_by = next(
        (x for x in household.member if x.user.username == args['paid_by']), None)
    if paid_by:
        expense.paid_by_id = paid_by.user_id

    expense.save()

    for paid_for in args['paid_for']:
        paid_for_member = next(
            (x for x in household.member if x.user.username == paid_for['username']), None)
        if not paid_for_member:
            continue
        con = ExpensePaidFor()
        con.expense = expense
        con.user_id = paid_for_member.user_id
        con.factor = paid_for['factor']
        con.save()
