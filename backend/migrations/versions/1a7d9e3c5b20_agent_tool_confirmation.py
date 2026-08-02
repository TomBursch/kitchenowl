"""add agent tool confirmation state

Revision ID: 1a7d9e3c5b20
Revises: f6a2b91c4d07
"""

import sqlalchemy as sa
from alembic import op


revision = "1a7d9e3c5b20"
down_revision = "f6a2b91c4d07"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.add_column(
            sa.Column(
                "requires_confirmation",
                sa.Boolean(),
                nullable=False,
                server_default=sa.false(),
            )
        )


def downgrade():
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.drop_column("requires_confirmation")