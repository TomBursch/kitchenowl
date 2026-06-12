"""recipe photos list

Revision ID: 6950c7b662d1
Revises: 0b10d67750be
Create Date: 2026-05-29 21:32:23.419806

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '6950c7b662d1'
down_revision = '0b10d67750be'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('recipe', schema=None) as batch_op:
        batch_op.add_column(sa.Column('photos', sa.JSON(), nullable=True))


def downgrade():
    with op.batch_alter_table('recipe', schema=None) as batch_op:
        batch_op.drop_column('photos')
