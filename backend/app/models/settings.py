from app import db
from app.helpers import DbModelMixin, TimestampMixin


class Settings(db.Model, DbModelMixin, TimestampMixin):
    __tablename__ = 'settings'

    planner_feature = db.Column(db.Boolean(), primary_key=True, default=True)
    expenses_feature = db.Column(db.Boolean(), primary_key=True, default=True)

    @classmethod
    def get(cls):
        settings = cls.query.first()
        if not settings:
            settings = cls()
            settings.save()
        return settings
