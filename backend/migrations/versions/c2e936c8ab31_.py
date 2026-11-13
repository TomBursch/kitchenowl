"""empty message

Revision ID: c2e936c8ab31
Revises: ff57ce339705
Create Date: 2026-11-13 20:26:58.476901

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = "c2e936c8ab31"
down_revision = "ff57ce339705"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    if "postgresql" in bind.engine.name:
        op.execute("CREATE EXTENSION IF NOT EXISTS unaccent")


def downgrade():
    bind = op.get_bind()
    if "postgresql" in bind.engine.name:
        op.execute("DROP EXTENSION unaccent")
