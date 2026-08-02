"""Add group_label column to agent_recipe_card.

Revision ID: c8d2f3a14c01
Revises: b7c1e9d20b15
Create Date: 2026-05-01 00:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "c8d2f3a14c01"
down_revision = "b7c1e9d20b15"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("agent_recipe_card") as batch_op:
        batch_op.add_column(
            sa.Column("group_label", sa.String(length=64), nullable=True)
        )


def downgrade():
    with op.batch_alter_table("agent_recipe_card") as batch_op:
        batch_op.drop_column("group_label")
