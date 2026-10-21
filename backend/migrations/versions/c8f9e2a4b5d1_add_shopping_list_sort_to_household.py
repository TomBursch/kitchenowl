"""Add shopping list sort configuration to household

Revision ID: c8f9e2a4b5d1
Revises: aa5d56fe28bb
Create Date: 2026-03-13 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c8f9e2a4b5d1'
down_revision = 'aa5d56fe28bb'
branch_labels = None
depends_on = None


def upgrade():
    # Neue Spalten zu household hinzufügen
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.add_column(sa.Column('shopping_list_sort_type', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('shopping_list_sort_order', sa.Integer(), nullable=False, server_default='0'))


def downgrade():
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.drop_column('shopping_list_sort_order')
        batch_op.drop_column('shopping_list_sort_type')
