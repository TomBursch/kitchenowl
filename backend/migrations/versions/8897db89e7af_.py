"""empty message

Revision ID: 8897db89e7af
Revises: c058421705ec
Create Date: 2023-05-15 12:26:45.223242

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import orm

DeclarativeBase = orm.declarative_base()


# revision identifiers, used by Alembic.
revision = '8897db89e7af'
down_revision = 'c058421705ec'
branch_labels = None
depends_on = None


class User(DeclarativeBase):
    __tablename__ = 'user'
    id = sa.Column(sa.Integer, primary_key=True)
    admin = sa.Column('admin', sa.Boolean(), nullable=False)

def upgrade():
    bind = op.get_bind()
    session = orm.Session(bind=bind)
    if session.query(User).count() > 0 and session.query(User).filter(User.admin == True).count() == 0:
        admin = session.query(User).order_by(User.id).first()
        admin.admin = True
        try:
            session.add(admin)
            session.commit()
        except Exception as e:
            session.rollback()
            raise e



def downgrade():
    pass
