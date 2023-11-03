from sqlalchemy import func
from app.models import Expense, ExpensePaidFor, HouseholdMember
from app import db


def recalculateBalances(household_id):
    for member in HouseholdMember.find_by_household(household_id):
        member.expense_balance = float(
            Expense.query.with_entities(func.sum(Expense.amount).label("balance"))
            .filter(
                Expense.paid_by_id == member.user_id,
                Expense.household_id == household_id,
            )
            .first()
            .balance
            or 0
        )
        for paid_for in ExpensePaidFor.query.filter(
            ExpensePaidFor.user_id == member.user_id,
            ExpensePaidFor.expense_id.in_(
                db.session.query(Expense.id)
                .filter(Expense.household_id == household_id)
                .scalar_subquery()
            ),
        ).all():
            factor_sum = (
                Expense.query.with_entities(
                    func.sum(ExpensePaidFor.factor).label("factor_sum")
                )
                .filter(ExpensePaidFor.expense_id == paid_for.expense_id)
                .first()
                .factor_sum
            )
            member.expense_balance = (
                member.expense_balance
                - (paid_for.factor / factor_sum) * paid_for.expense.amount
            )
        member.save()
