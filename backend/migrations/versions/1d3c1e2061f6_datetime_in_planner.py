"""datetime in planner

Revision ID: 1d3c1e2061f6
Revises: 22dbfbf4cc33
Create Date: 2025-02-23 21:11:07.978331

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import orm
from datetime import datetime, timedelta
DeclarativeBase = orm.declarative_base()


class Planner(DeclarativeBase):
    __tablename__ = "planner"

    recipe_id = sa.Column(sa.Integer, primary_key=True)
    day = sa.Column(sa.Integer, primary_key=True)
    cooking_date = sa.Column(sa.DateTime)


# revision identifiers, used by Alembic.
revision = "1d3c1e2061f6"
down_revision = '22dbfbf4cc33'
branch_labels = None
depends_on = None

def next_weekday(weekday_number: int) -> datetime:
    if weekday_number < 0:
        return datetime.min
    # Get today's date
    today = datetime.now()
    
    # Calculate how many days to add to get to the next specified weekday
    days_ahead = (weekday_number - today.weekday() + 7) % 7
    
    # Calculate the next weekday date
    next_date = today + timedelta(days=days_ahead)
    
    return next_date

def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('planner', schema=None) as batch_op:
        batch_op.add_column(sa.Column('cooking_date', sa.DateTime(), nullable=True))

    # Data migration
    bind = op.get_bind()
    session = orm.Session(bind=bind)

    planner = session.query(Planner).all()
    for plan in planner:
        plan.cooking_date = next_weekday(plan.day)

    try:
        session.bulk_save_objects(planner)
        session.commit()
    except Exception as e:
        session.rollback()
        raise e
    # Data migration end
    
    with op.batch_alter_table('planner', schema=None) as batch_op:
        batch_op.alter_column('cooking_date', nullable=False)
        batch_op.drop_constraint('pk_planner')
        batch_op.create_primary_key('pk_planner', ['recipe_id', 'cooking_date'])
        batch_op.drop_column('day')

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('planner', schema=None) as batch_op:
        batch_op.add_column(sa.Column('day', sa.INTEGER(), nullable=False))
        batch_op.drop_constraint('pk_planner')
        batch_op.create_primary_key('pk_planner', ['recipe_id', 'day'])
        batch_op.drop_column('cooking_date')
    # ### end Alembic commands ###
