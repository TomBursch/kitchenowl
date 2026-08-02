"""Add initial_greeting to llm_config.

Revision ID: 7a2c5e1d4f01
Revises: 5bcb6a481926
Create Date: 2026-04-28 09:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "7a2c5e1d4f01"
down_revision = "5bcb6a481926"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.add_column(sa.Column("initial_greeting", sa.Text(), nullable=True))


def downgrade():
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.drop_column("initial_greeting")
