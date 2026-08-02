"""Add agent_feature flag to household.

Revision ID: 9c3a1f5e8b21
Revises: 7a2c5e1d4f01
Create Date: 2026-04-28 12:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "9c3a1f5e8b21"
down_revision = "7a2c5e1d4f01"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("household") as batch_op:
        batch_op.add_column(
            sa.Column(
                "agent_feature",
                sa.Boolean(),
                nullable=False,
                server_default=sa.false(),
            )
        )
    # Enable the agent feature for households that already have an enabled
    # LLM configuration so the chat tab does not silently disappear after
    # the upgrade.
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "llm_config" in inspector.get_table_names():
        bind.execute(
            sa.text(
                "UPDATE household SET agent_feature = :true_val "
                "WHERE id IN (SELECT household_id FROM llm_config WHERE enabled = :true_val)"
            ),
            {"true_val": True},
        )


def downgrade():
    with op.batch_alter_table("household") as batch_op:
        batch_op.drop_column("agent_feature")
