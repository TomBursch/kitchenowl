"""Agent personas + chat title-lock + member default persona.

Revision ID: c4e8d2f15a30
Revises: 9c3a1f5e8b21
Create Date: 2026-04-28 18:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "c4e8d2f15a30"
down_revision = "9c3a1f5e8b21"
branch_labels = None
depends_on = None


def upgrade():
    # New table: agent_persona
    op.create_table(
        "agent_persona",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("household_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("icon", sa.String(length=64), nullable=True),
        sa.Column("system_prompt", sa.Text(), nullable=True),
        sa.Column("initial_greeting", sa.Text(), nullable=True),
        sa.Column("temperature", sa.Float(), nullable=True),
        sa.Column(
            "is_default_global",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["household_id"],
            ["household.id"],
            name=op.f("fk_agent_persona_household_id_household"),
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["user.id"],
            name=op.f("fk_agent_persona_user_id_user"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_agent_persona")),
    )
    with op.batch_alter_table("agent_persona") as batch_op:
        batch_op.create_index(
            op.f("ix_agent_persona_household_id"), ["household_id"], unique=False
        )
        batch_op.create_index(
            op.f("ix_agent_persona_user_id"), ["user_id"], unique=False
        )

    # Extend agent_chat with title-lock + persona reference.
    with op.batch_alter_table("agent_chat") as batch_op:
        batch_op.add_column(
            sa.Column(
                "title_locked",
                sa.Boolean(),
                nullable=False,
                server_default=sa.false(),
            )
        )
        batch_op.add_column(
            sa.Column(
                "title_auto",
                sa.Boolean(),
                nullable=False,
                server_default=sa.true(),
            )
        )
        batch_op.add_column(sa.Column("persona_id", sa.Integer(), nullable=True))
        batch_op.create_foreign_key(
            op.f("fk_agent_chat_persona_id_agent_persona"),
            "agent_persona",
            ["persona_id"],
            ["id"],
            ondelete="SET NULL",
        )
        batch_op.create_index(
            op.f("ix_agent_chat_persona_id"), ["persona_id"], unique=False
        )

    # Per-member default persona.
    with op.batch_alter_table("household_member") as batch_op:
        batch_op.add_column(
            sa.Column("default_persona_id", sa.Integer(), nullable=True)
        )
        batch_op.create_foreign_key(
            op.f("fk_household_member_default_persona_id_agent_persona"),
            "agent_persona",
            ["default_persona_id"],
            ["id"],
            ondelete="SET NULL",
        )

    # Seed: every household that already has an LLM config (i.e. ever
    # configured the agent) gets a default global persona so existing chats
    # and the UI's "pick a persona" picker have something to point at.
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if (
        "llm_config" in inspector.get_table_names()
        and "agent_persona" in inspector.get_table_names()
    ):
        bind.execute(
            sa.text(
                "INSERT INTO agent_persona (household_id, user_id, name, "
                "is_default_global, created_at, updated_at) "
                "SELECT lc.household_id, NULL, :name, :true_val, "
                "       CURRENT_TIMESTAMP, CURRENT_TIMESTAMP "
                "FROM llm_config lc "
                "WHERE NOT EXISTS ("
                "    SELECT 1 FROM agent_persona ap "
                "    WHERE ap.household_id = lc.household_id "
                "      AND ap.user_id IS NULL "
                "      AND ap.is_default_global = :true_val"
                ")"
            ),
            {"name": "Standard", "true_val": True},
        )


def downgrade():
    with op.batch_alter_table("household_member") as batch_op:
        batch_op.drop_constraint(
            op.f("fk_household_member_default_persona_id_agent_persona"),
            type_="foreignkey",
        )
        batch_op.drop_column("default_persona_id")

    with op.batch_alter_table("agent_chat") as batch_op:
        batch_op.drop_index(op.f("ix_agent_chat_persona_id"))
        batch_op.drop_constraint(
            op.f("fk_agent_chat_persona_id_agent_persona"), type_="foreignkey"
        )
        batch_op.drop_column("persona_id")
        batch_op.drop_column("title_auto")
        batch_op.drop_column("title_locked")

    with op.batch_alter_table("agent_persona") as batch_op:
        batch_op.drop_index(op.f("ix_agent_persona_user_id"))
        batch_op.drop_index(op.f("ix_agent_persona_household_id"))
    op.drop_table("agent_persona")
