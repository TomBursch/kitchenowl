"""empty message

Revision ID: 718193c0581a
Revises: 681d624f0d5f
Create Date: 2021-12-04 14:32:12.860932

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '718193c0581a'
down_revision = '681d624f0d5f'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('user', sa.Column('admin', sa.Boolean(), nullable=True))
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('user', 'admin')
    # ### end Alembic commands ###
