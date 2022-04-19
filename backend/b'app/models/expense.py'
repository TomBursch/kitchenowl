from app import db
from app.helpers import DbModelMixin, TimestampMixin


class Expense(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'expense'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128))
    amount = db.Column(db.Float())
    category_id = db.Column(db.Integer, db.ForeignKey('expense_category.id'))
    photo = db.Column(db.String())
    paid_by_id = db.Column(db.Integer, db.ForeignKey('user.id'))

    category = db.relationship("ExpenseCategory")
    paid_by = db.relationship("User")
    paid_for = db.relationship(
        'ExpensePaidFor', back_populates='expense', cascade="all, delete-orphan")

    def obj_to_full_dict(self):
        res = super().obj_to_dict()
        paidFor = ExpensePaidFor.query.filter(ExpensePaidFor.expense_id == self.id).join(
            ExpensePaidFor.user).order_by(
            ExpensePaidFor.expense_id).all()
        res['paid_for'] = [e.obj_to_dict() for e in paidFor]
        if (self.category):
            res['category'] = self.category.name
        return res

    @classmethod
    def find_by_name(cls, name):
        return cls.query.filter(cls.name == name).first()

    @classmethod
    def find_by_id(cls, id):
        return cls.query.filter(cls.id == id).join(Expense.category, isouter=True).first()


class ExpensePaidFor(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'expense_paid_for'

    expense_id = db.Column(db.Integer, db.ForeignKey(
        'expense.id'), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), primary_key=True)
    factor = db.Column(db.Integer())

    expense = db.relationship("Expense", back_populates='paid_for')
    user = db.relationship("User", back_populates='expenses_paid_for')

    def obj_to_user_dict(self):
        res = self.user.obj_to_dict()
        res['factor'] = getattr(self, 'factor')
        res['created_at'] = getattr(self, 'created_at')
        res['updated_at'] = getattr(self, 'updated_at')
        return res

    @classmethod
    def find_by_ids(cls, expense_id, user_id):
        return cls.query.filter(cls.expense_id == expense_id, cls.user_id == user_id).first()
