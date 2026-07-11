"""add recipe_tombstone table

Revision ID: a1b2c3d4e5f6
Revises: 0b10d67750be
Create Date: 2026-07-11 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a1b2c3d4e5f6'
down_revision = '0b10d67750be'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'recipe_tombstone',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('recipe_id', sa.Integer(), nullable=False),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ['household_id'], ['household.id'],
            name=op.f('fk_recipe_tombstone_household_id_household'),
        ),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_recipe_tombstone')),
    )
    with op.batch_alter_table('recipe_tombstone', schema=None) as batch_op:
        batch_op.create_index(
            op.f('ix_recipe_tombstone_household_id'), ['household_id'], unique=False
        )
        batch_op.create_index(
            op.f('ix_recipe_tombstone_recipe_id'), ['recipe_id'], unique=False
        )


def downgrade():
    with op.batch_alter_table('recipe_tombstone', schema=None) as batch_op:
        batch_op.drop_index(op.f('ix_recipe_tombstone_recipe_id'))
        batch_op.drop_index(op.f('ix_recipe_tombstone_household_id'))
    op.drop_table('recipe_tombstone')
