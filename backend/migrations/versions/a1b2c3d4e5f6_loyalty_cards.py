"""Add loyalty cards feature

Revision ID: a1b2c3d4e5f6
Revises: bd383e73ef4d
Create Date: 2025-12-26 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a1b2c3d4e5f6'
down_revision = 'bd383e73ef4d'
branch_labels = None
depends_on = None


def upgrade():
    # Create loyalty_card table
    op.create_table(
        'loyalty_card',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('barcode_type', sa.String(length=32), nullable=False),
        sa.Column('barcode_data', sa.String(length=256), nullable=False),
        sa.Column('description', sa.String(length=512), nullable=True),
        sa.Column('color', sa.Integer(), nullable=True),
        sa.Column('photo', sa.String(), nullable=True),
        sa.Column('household_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['household_id'], ['household.id'], ),
        sa.ForeignKeyConstraint(['photo'], ['file.filename'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_loyalty_card_household_id'), 'loyalty_card', ['household_id'], unique=False)

    # Add loyalty_cards_feature column to household
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.add_column(sa.Column('loyalty_cards_feature', sa.Boolean(), nullable=False, server_default='1'))


def downgrade():
    # Remove loyalty_cards_feature column from household
    with op.batch_alter_table('household', schema=None) as batch_op:
        batch_op.drop_column('loyalty_cards_feature')

    # Drop loyalty_card table
    op.drop_index(op.f('ix_loyalty_card_household_id'), table_name='loyalty_card')
    op.drop_table('loyalty_card')

