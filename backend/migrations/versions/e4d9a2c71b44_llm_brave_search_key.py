"""Add brave_search_api_key_encrypted to llm_config.

Revision ID: e4d9a2c71b44
Revises: c8d2f3a14c01
Create Date: 2026-05-06 00:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "e4d9a2c71b44"
down_revision = "c8d2f3a14c01"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.add_column(
            sa.Column("brave_search_api_key_encrypted", sa.String(), nullable=True)
        )


def downgrade():
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.drop_column("brave_search_api_key_encrypted")
