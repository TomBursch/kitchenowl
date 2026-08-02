"""Agent recipe cards + suggestion guideline + message attachments.

Revision ID: b7c1e9d20b15
Revises: a4f3c2e9b108
Create Date: 2026-04-29 00:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "b7c1e9d20b15"
down_revision = "a4f3c2e9b108"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.add_column(sa.Column("suggestion_guideline", sa.Text(), nullable=True))

    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.add_column(sa.Column("attachments_json", sa.Text(), nullable=True))

    op.create_table(
        "agent_recipe_card",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "chat_id",
            sa.Integer(),
            sa.ForeignKey("agent_chat.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "recipe_id",
            sa.Integer(),
            sa.ForeignKey("recipe.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("payload_json", sa.Text(), nullable=True),
        sa.Column("position", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("closed_at", sa.DateTime(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.func.current_timestamp(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.func.current_timestamp(),
        ),
    )


def downgrade():
    op.drop_table("agent_recipe_card")
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.drop_column("attachments_json")
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.drop_column("suggestion_guideline")
