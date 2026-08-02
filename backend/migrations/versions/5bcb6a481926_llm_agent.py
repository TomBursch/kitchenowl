"""Add LLM agent tables: llm_config, agent_chat, agent_message.

Revision ID: 5bcb6a481926
Revises: bd383e73ef4d
Create Date: 2026-04-27 15:10:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "5bcb6a481926"
down_revision = "bd383e73ef4d"
branch_labels = None
depends_on = None


llm_provider_enum = sa.Enum(
    "OPENAI", "GEMINI", "CUSTOM", name="llmprovidertype"
)
agent_role_enum = sa.Enum(
    "SYSTEM", "USER", "ASSISTANT", "TOOL", name="agentmessagerole"
)


def upgrade():
    op.create_table(
        "llm_config",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("household_id", sa.Integer(), nullable=False),
        sa.Column("provider", llm_provider_enum, nullable=False),
        sa.Column("base_url", sa.String(length=512), nullable=True),
        sa.Column("model", sa.String(length=128), nullable=True),
        sa.Column("api_key_encrypted", sa.String(), nullable=True),
        sa.Column("system_prompt", sa.Text(), nullable=True),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("max_tokens", sa.Integer(), nullable=True),
        sa.Column("temperature", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["household_id"],
            ["household.id"],
            name=op.f("fk_llm_config_household_id_household"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_llm_config")),
        sa.UniqueConstraint("household_id", name=op.f("uq_llm_config_household_id")),
    )
    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.create_index(
            op.f("ix_llm_config_household_id"), ["household_id"], unique=False
        )

    op.create_table(
        "agent_chat",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("household_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["household_id"],
            ["household.id"],
            name=op.f("fk_agent_chat_household_id_household"),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"], ["user.id"], name=op.f("fk_agent_chat_user_id_user")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_agent_chat")),
    )
    with op.batch_alter_table("agent_chat") as batch_op:
        batch_op.create_index(
            op.f("ix_agent_chat_household_id"), ["household_id"], unique=False
        )
        batch_op.create_index(
            op.f("ix_agent_chat_user_id"), ["user_id"], unique=False
        )

    op.create_table(
        "agent_message",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("chat_id", sa.Integer(), nullable=False),
        sa.Column("role", agent_role_enum, nullable=False),
        sa.Column("content", sa.Text(), nullable=True),
        sa.Column("tool_calls", sa.Text(), nullable=True),
        sa.Column("tool_call_id", sa.String(length=128), nullable=True),
        sa.Column("tool_name", sa.String(length=128), nullable=True),
        sa.Column("created_recipe_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["chat_id"],
            ["agent_chat.id"],
            name=op.f("fk_agent_message_chat_id_agent_chat"),
        ),
        sa.ForeignKeyConstraint(
            ["created_recipe_id"],
            ["recipe.id"],
            name=op.f("fk_agent_message_created_recipe_id_recipe"),
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_agent_message")),
    )
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.create_index(
            op.f("ix_agent_message_chat_id"), ["chat_id"], unique=False
        )


def downgrade():
    with op.batch_alter_table("agent_message") as batch_op:
        batch_op.drop_index(op.f("ix_agent_message_chat_id"))
    op.drop_table("agent_message")

    with op.batch_alter_table("agent_chat") as batch_op:
        batch_op.drop_index(op.f("ix_agent_chat_user_id"))
        batch_op.drop_index(op.f("ix_agent_chat_household_id"))
    op.drop_table("agent_chat")

    with op.batch_alter_table("llm_config") as batch_op:
        batch_op.drop_index(op.f("ix_llm_config_household_id"))
    op.drop_table("llm_config")

    bind = op.get_bind()
    agent_role_enum.drop(bind, checkfirst=True)
    llm_provider_enum.drop(bind, checkfirst=True)
