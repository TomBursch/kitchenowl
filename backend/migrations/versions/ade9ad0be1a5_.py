"""empty message

Revision ID: ade9ad0be1a5
Revises: 3647c9eb1881
Create Date: 2023-08-31 13:57:34.979533

"""
import os
from alembic import op
import blurhash
from PIL import Image
import sqlalchemy as sa
from sqlalchemy import inspect, orm

from app.config import UPLOAD_FOLDER, db

DeclarativeBase = orm.declarative_base()


# revision identifiers, used by Alembic.
revision = 'ade9ad0be1a5'
down_revision = '3647c9eb1881'
branch_labels = None
depends_on = None


class File(DeclarativeBase):
    __tablename__ = 'file'
    filename = sa.Column(sa.String(), primary_key=True)
    blur_hash = sa.Column(sa.String(length=40), nullable=True)


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    inspector = inspect(db.engine)
    # workaround since the inspector can only return existing tables which they don't if upgrade is run on an empty DB
    # Only add the row if it does not exists (e.g. if the migration/hash calculation failed and is restarted)
    if not 'file' in inspector.get_table_names() or not any(c['name'] == 'blur_hash' for c in inspector.get_columns('file')):
        with op.batch_alter_table('file', schema=None) as batch_op:
            batch_op.add_column(sa.Column('blur_hash', sa.String(length=40), nullable=True))

    bind = op.get_bind()
    session = orm.Session(bind=bind)
    for file in session.query(File).filter(File.blur_hash == None).all():
        try:
            with Image.open(os.path.join(UPLOAD_FOLDER, file.filename)) as image:
                image.thumbnail((100, 100))
                file.blur_hash = blurhash.encode(image, x_components=4, y_components=3)
            session.add(file)
        except FileNotFoundError:
            session.delete(file)
        except Exception:
            pass
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        raise e
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('file', schema=None) as batch_op:
        batch_op.drop_column('blur_hash')

    # ### end Alembic commands ###
