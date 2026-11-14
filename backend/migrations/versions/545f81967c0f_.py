"""add code_verifier to oidc_request

Revision ID: 545f81967c0f
Revises: c2e936c8ab31
Create Date: 2026-11-13 18:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '545f81967c0f'
down_revision = 'c2e936c8ab31'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('oidc_request', schema=None) as batch_op:
        batch_op.add_column(sa.Column('code_verifier', sa.String(length=128), nullable=True))


def downgrade():
    with op.batch_alter_table('oidc_request', schema=None) as batch_op:
        batch_op.drop_column('code_verifier')
