"""empty message

Revision ID: 9b45d9dd5b8e
Revises: ee2ba4d37d8b
Create Date: 2023-11-15 12:01:18.288028

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '9b45d9dd5b8e'
down_revision = 'ee2ba4d37d8b'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('oidc_link',
    sa.Column('sub', sa.String(length=256), nullable=False),
    sa.Column('provider', sa.String(length=24), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.Column('updated_at', sa.DateTime(), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['user.id'], name=op.f('fk_oidc_link_user_id_user')),
    sa.PrimaryKeyConstraint('sub', 'provider', name=op.f('pk_oidc_link'))
    )
    with op.batch_alter_table('oidc_link', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_oidc_link_user_id'), ['user_id'], unique=False)

    op.create_table('oidc_request',
    sa.Column('state', sa.String(length=256), nullable=False),
    sa.Column('provider', sa.String(length=24), nullable=False),
    sa.Column('nonce', sa.String(length=256), nullable=False),
    sa.Column('redirect_uri', sa.String(length=256), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.Column('updated_at', sa.DateTime(), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['user.id'], name=op.f('fk_oidc_request_user_id_user')),
    sa.PrimaryKeyConstraint('state', 'provider', name=op.f('pk_oidc_request'))
    )
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.alter_column('password',
               existing_type=sa.VARCHAR(length=256),
               nullable=True)

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.alter_column('password',
               existing_type=sa.VARCHAR(length=256),
               nullable=False)

    op.drop_table('oidc_request')
    with op.batch_alter_table('oidc_link', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_oidc_link_user_id'))

    op.drop_table('oidc_link')
    # ### end Alembic commands ###
