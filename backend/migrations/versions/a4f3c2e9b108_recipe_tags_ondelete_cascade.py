"""recipe_tags FKs: ON DELETE CASCADE so tag/recipe deletion cleans up.

Revision ID: a4f3c2e9b108
Revises: 8e1f2a3b4c5d
Create Date: 2025-01-01 00:00:00.000000

"""

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision = "a4f3c2e9b108"
down_revision = "8e1f2a3b4c5d"
branch_labels = None
depends_on = None


def _rebuild(ondelete: str | None) -> None:
    # Use ``recreate='always'`` so SQLite's batch mode rebuilds the table
    # from scratch with the FK definitions we provide via ``table_args``,
    # bypassing the need to know the original (anonymous) FK constraint
    # names. On Postgres the same definitions are applied via
    # drop+recreate of the named constraints alembic generates.
    table_args = [
        sa.ForeignKeyConstraint(
            ["tag_id"], ["tag.id"],
            name="recipe_tags_tag_id_fkey",
            ondelete=ondelete,
        ),
        sa.ForeignKeyConstraint(
            ["recipe_id"], ["recipe.id"],
            name="recipe_tags_recipe_id_fkey",
            ondelete=ondelete,
        ),
    ]
    with op.batch_alter_table(
        "recipe_tags", recreate="always", table_args=table_args
    ):
        pass


def upgrade():
    _rebuild(ondelete="CASCADE")


def downgrade():
    _rebuild(ondelete=None)
