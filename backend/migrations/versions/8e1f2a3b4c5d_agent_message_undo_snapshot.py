"""Add undo_snapshot to agent_message.

Revision ID: 8e1f2a3b4c5d
Revises: c4e8d2f15a30
Create Date: 2026-04-29 10:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "8e1f2a3b4c5d"
down_revision = "c4e8d2f15a30"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.add_column(sa.Column("undo_snapshot", sa.Text(), nullable=True))


def downgrade():
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.drop_column("undo_snapshot")
